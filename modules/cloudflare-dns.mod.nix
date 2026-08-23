{self, ...}: {
  flake.nixosModules.cloudflareDns = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = lib.attrByPath ["homelab" "proxy" "dns"] {} config;
    proxyEnabled = lib.attrByPath ["homelab" "proxy" "enable"] false config;
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasSopsSecrets = lib.hasAttrByPath ["sops" "secrets"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;

    dnsEntries =
      (lib.mapAttrsToList (domain: target: {
          inherit domain;
          type = "CNAME";
          value = target;
          proxied = cfg.defaultProxied;
          ttl = cfg.defaultTTL;
        })
        cfg.cnames)
      ++ lib.flatten (lib.mapAttrsToList
        (domain: hostCfg: let
          dnsCfg = hostCfg.dns;
          recordType =
            if dnsCfg.type == null
            then cfg.defaultType
            else dnsCfg.type;
          proxied =
            if dnsCfg.proxied == null
            then cfg.defaultProxied
            else dnsCfg.proxied;
          ttl =
            if dnsCfg.ttl == null
            then cfg.defaultTTL
            else dnsCfg.ttl;
          target =
            if dnsCfg.target == null
            then cfg.defaultTarget
            else dnsCfg.target;
        in
          lib.optional dnsCfg.enable {
            inherit domain proxied ttl;
            type = recordType;
            value =
              if recordType == "A"
              then
                if dnsCfg.value == null
                then cfg.defaultValue
                else dnsCfg.value
              else target;
          })
        (lib.attrByPath ["homelab" "proxy" "hosts"] {} config));

    dnsConfig = pkgs.writeText "cloudflare-dns-config.json" (builtins.toJSON {
      inherit (cfg) defaultTarget managedComment tokenPath zoneNames;
      records = dnsEntries;
    });

    cloudflareDnsLib = pkgs.writeText "cloudflare-dns-lib.py" ''
      import fnmatch
      import json
      import os
      import sys
      import urllib.error
      import urllib.parse
      import urllib.request


      def load_config(path):
          with open(path, "r", encoding="utf-8") as fh:
              return json.load(fh)


      def load_token(config):
          for env_name in ("CLOUDFLARE_API_TOKEN", "CF_API_TOKEN"):
              value = os.environ.get(env_name)
              if value:
                  return value

          token_path = config.get("tokenPath")
          if token_path and os.path.exists(token_path):
              with open(token_path, "r", encoding="utf-8") as fh:
                  return fh.read().strip()

          raise SystemExit(
              "missing Cloudflare API token: set CLOUDFLARE_API_TOKEN/CF_API_TOKEN or enable the sops-backed token file"
          )


      def api_request(token, method, path, params=None, payload=None):
          url = "https://api.cloudflare.com/client/v4" + path
          if params:
              url += "?" + urllib.parse.urlencode(params)

          data = None
          headers = {
              "Authorization": f"Bearer {token}",
              "Content-Type": "application/json",
          }
          if payload is not None:
              data = json.dumps(payload).encode("utf-8")

          request = urllib.request.Request(url, method=method, headers=headers, data=data)
          try:
              with urllib.request.urlopen(request) as response:
                  result = json.load(response)
          except urllib.error.HTTPError as exc:
              body = exc.read().decode("utf-8", errors="replace")
              raise SystemExit(f"Cloudflare API {method} {path} failed: {exc.code} {body}")

          if not result.get("success", False):
              raise SystemExit(f"Cloudflare API {method} {path} returned errors: {result.get('errors', [])}")

          return result


      def select_records(config, patterns):
          records = config["records"]
          if not patterns:
              return records
          return [
              record
              for record in records
              if any(fnmatch.fnmatch(record["domain"], pattern) for pattern in patterns)
          ]


      def resolve_zone(domain, zone_names):
          matches = [zone for zone in zone_names if domain == zone or domain.endswith("." + zone)]
          if not matches:
              raise SystemExit(f"no configured Cloudflare zone matches {domain}")
          return max(matches, key=len)


      def get_zone_id(token, cache, zone_name):
          if zone_name in cache:
              return cache[zone_name]
          result = api_request(token, "GET", "/zones", params={"name": zone_name, "per_page": 1})
          zones = result.get("result", [])
          if len(zones) != 1:
              raise SystemExit(f"expected exactly one Cloudflare zone named {zone_name}, got {len(zones)}")
          cache[zone_name] = zones[0]["id"]
          return cache[zone_name]


      def list_zone_records(token, zone_id):
          page = 1
          records = []
          while True:
              result = api_request(token, "GET", f"/zones/{zone_id}/dns_records", params={"page": page, "per_page": 500})
              records.extend(result.get("result", []))
              info = result.get("result_info", {})
              if page >= info.get("total_pages", 1):
                  break
              page += 1
          return records


      def desired_by_key(config, records):
          zone_names = config["zoneNames"]
          desired = {}
          for record in records:
              zone_name = resolve_zone(record["domain"], zone_names)
              key = (zone_name, record["domain"], record["type"])
              desired[key] = {
                  "zone_name": zone_name,
                  "name": record["domain"],
                  "type": record["type"],
                  "content": record["value"],
                  "proxied": record["proxied"],
                  "ttl": record["ttl"],
              }
          return desired


      def build_plan(config, patterns):
          token = load_token(config)
          selected_records = select_records(config, patterns)
          desired = desired_by_key(config, selected_records)
          selected_domains = {record["domain"] for record in selected_records}
          zone_cache = {}
          managed_comment = config["managedComment"]

          zone_to_records = {}
          for zone_name in config["zoneNames"]:
              zone_id = get_zone_id(token, zone_cache, zone_name)
              zone_to_records[zone_name] = list_zone_records(token, zone_id)

          creates = []
          updates = []
          deletes = []
          conflicts = []

          existing_by_key = {}
          existing_by_name = {}
          for zone_name, records in zone_to_records.items():
              for record in records:
                  key = (zone_name, record["name"], record["type"])
                  name_key = (zone_name, record["name"])
                  existing_by_key.setdefault(key, []).append(record)
                  existing_by_name.setdefault(name_key, []).append(record)

          for key, wanted in desired.items():
              existing = existing_by_key.get(key, [])
              same_name = existing_by_name.get((wanted["zone_name"], wanted["name"]), [])
              incompatible = [
                  record
                  for record in same_name
                  if record["type"] != wanted["type"] and (wanted["type"] == "CNAME" or record["type"] == "CNAME")
              ]
              deletes.extend(incompatible)

              if existing:
                  current = existing[0]
                  deletes.extend(existing[1:])
                  same = (
                      current.get("content") == wanted["content"]
                      and current.get("proxied") == wanted["proxied"]
                      and current.get("ttl") == wanted["ttl"]
                      and (current.get("comment") or "") == managed_comment
                  )
                  if not same:
                      updates.append({"current": current, "wanted": wanted})
              else:
                  creates.append(wanted)

          for key, existing in existing_by_key.items():
              if key in desired:
                  continue
              if patterns and key[1] not in selected_domains:
                  continue
              for record in existing:
                  if (record.get("comment") or "") == managed_comment:
                      deletes.append(record)

          return token, zone_cache, {
              "creates": creates,
              "updates": updates,
              "deletes": deletes,
              "conflicts": conflicts,
          }


      def print_plan(plan):
          if plan["conflicts"]:
              print("Conflicts:")
              for conflict in plan["conflicts"]:
                  wanted = conflict["wanted"]
                  print(f"  conflict {wanted['type']} {wanted['name']} -> {wanted['content']} ({conflict['reason']}) ids={conflict['existing']}")

          for record in plan["creates"]:
              print(f"  create {record['type']} {record['name']} -> {record['content']} proxied={record['proxied']} ttl={record['ttl']}")

          for update in plan["updates"]:
              current = update["current"]
              wanted = update["wanted"]
              print(
                  f"  update {wanted['type']} {wanted['name']} {current['content']} -> {wanted['content']} "
                  f"proxied {current.get('proxied')} -> {wanted['proxied']} ttl {current.get('ttl')} -> {wanted['ttl']}"
              )

          for record in plan["deletes"]:
              print(f"  delete {record['type']} {record['name']} -> {record['content']}")

          if not any(plan.values()):
              print("  no changes")


      def apply_plan(config, token, zone_cache, plan):
          managed_comment = config["managedComment"]

          if plan["conflicts"]:
              print_plan(plan)
              raise SystemExit("refusing to push while unmanaged DNS record collisions exist")

          for record in plan["deletes"]:
              zone_name = next(zone for zone in config["zoneNames"] if record["name"] == zone or record["name"].endswith("." + zone))
              zone_id = get_zone_id(token, zone_cache, zone_name)
              api_request(token, "DELETE", f"/zones/{zone_id}/dns_records/{record['id']}")

          for record in plan["creates"]:
              zone_id = get_zone_id(token, zone_cache, record["zone_name"])
              api_request(token, "POST", f"/zones/{zone_id}/dns_records", payload={
                  "type": record["type"],
                  "name": record["name"],
                  "content": record["content"],
                  "proxied": record["proxied"],
                  "ttl": record["ttl"],
                  "comment": managed_comment,
              })

          for update in plan["updates"]:
              current = update["current"]
              wanted = update["wanted"]
              zone_id = get_zone_id(token, zone_cache, wanted["zone_name"])
              api_request(token, "PUT", f"/zones/{zone_id}/dns_records/{current['id']}", payload={
                  "type": wanted["type"],
                  "name": wanted["name"],
                  "content": wanted["content"],
                  "proxied": wanted["proxied"],
                  "ttl": wanted["ttl"],
                  "comment": managed_comment,
              })

      def main(mode):
          config = load_config(os.environ["CLOUDFLARE_DNS_CONFIG"])
          token, zone_cache, plan = build_plan(config, sys.argv[2:])
          print_plan(plan)
          if mode == "push":
              apply_plan(config, token, zone_cache, plan)


      if __name__ == "__main__":
          main(sys.argv[1])
    '';

    dnsPreview = pkgs.writeShellScriptBin "cloudflare-dns-preview" ''
      export CLOUDFLARE_DNS_CONFIG=${lib.escapeShellArg dnsConfig}
      exec ${lib.getExe pkgs.python3} ${lib.escapeShellArg cloudflareDnsLib} preview "$@"
    '';

    dnsPush = pkgs.writeShellScriptBin "cloudflare-dns-push" ''
      export CLOUDFLARE_DNS_CONFIG=${lib.escapeShellArg dnsConfig}
      exec ${lib.getExe pkgs.python3} ${lib.escapeShellArg cloudflareDnsLib} push "$@"
    '';
  in {
    config = lib.mkIf proxyEnabled (lib.mkMerge [
      {
        assertions =
          [
            {
              assertion = cfg.zoneNames != [];
              message = "homelab.proxy.dns.zoneNames must list the Cloudflare zones managed by the DNS CLI.";
            }
          ]
          ++ map (record: {
            assertion = record.type != "CNAME" || record.value != record.domain;
            message = "Cloudflare DNS CNAME records cannot point a domain to itself: ${record.domain}.";
          })
          dnsEntries
          ++ map (record: {
            assertion = record.type != "A" || record.value != null;
            message = "Cloudflare DNS A records need homelab.proxy.dns.defaultValue or hosts.${record.domain}.dns.value.";
          })
          dnsEntries;

        environment.systemPackages = [
          dnsPreview
          dnsPush
        ];
      }

      (lib.optionalAttrs (hasPersistDirs && hasUserName) {
        persist.user.directories = [".local/state/cloudflare-dns"];
      })

      (lib.optionalAttrs (hasSopsSecrets && hasUserName) {
        sops.secrets."cloudflare/dns" = {
          sopsFile = self + /secrets/shared.yaml;
          path = cfg.tokenPath;
          owner = config.userName;
          group = "users";
          mode = "0400";
        };
      })
    ]);
  };
}
