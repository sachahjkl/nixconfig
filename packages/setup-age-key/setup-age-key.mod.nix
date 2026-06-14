_: {
  perSystem = {
    lib,
    pkgs,
    self',
    ...
  }: let
    setupAgeKey = pkgs.writeShellApplication {
      name = "setup-age-key";
      runtimeInputs = with pkgs; [
        coreutils
        gnugrep
        util-linux
      ];
      text = ''
                        set -euo pipefail

                        usage() {
                          cat <<'EOF'
        Usage: setup-age-key [--from-file PATH | --from-value AGE-SECRET-KEY-...] [--label LABEL] [--mount-point PATH] [--to-mounted-system[=PATH]]

                Bootstrap the shared SOPS age key into:
                  ~/.config/sops/age/keys.txt
                  /var/lib/sops-nix/key.txt

                If no explicit source is given, the command mounts the secret USB and looks for
                the key file there.

        Options:
          -f, --from-file PATH     Read the age key from a local file instead of the USB.
          -v, --from-value VALUE   Read the age key from the provided literal value.
          -l, --label LABEL        Override the expected USB label.
                                   Default: <hostname>.s
          -m, --mount-point PATH   Override the USB mount point.
                                   Default: /media/key
          -t, --to-mounted-system[=PATH]
                                   Also install the root-owned host copy into a mounted target
                                   system. Default target prefix: /mnt
          -h, --help               Show this help text.
        EOF
                }

                key_label_override=""
                mount_point_override=""
                key_file_override=""
                key_value_override=""
                mounted_system_prefix=""

                        while [ "$#" -gt 0 ]; do
                          case "$1" in
                            -f|--from-file)
                              if [ "$#" -lt 2 ]; then
                                printf 'Missing value for %s\n\n' "$1" >&2
                                usage >&2
                                exit 1
                              fi
                              key_file_override="$2"
                              shift 2
                              ;;
                            -v|--from-value)
                              if [ "$#" -lt 2 ]; then
                                printf 'Missing value for %s\n\n' "$1" >&2
                                usage >&2
                                exit 1
                              fi
                              key_value_override="$2"
                              shift 2
                              ;;
                            -l|--label)
                              if [ "$#" -lt 2 ]; then
                                printf 'Missing value for %s\n\n' "$1" >&2
                                usage >&2
                                exit 1
                              fi
                              key_label_override="$2"
                              shift 2
                              ;;
                    -m|--mount-point)
                      if [ "$#" -lt 2 ]; then
                        printf 'Missing value for %s\n\n' "$1" >&2
                        usage >&2
                        exit 1
                      fi
                      mount_point_override="$2"
                      shift 2
                      ;;
                    --to-mounted-system)
                      mounted_system_prefix="/mnt"
                      shift
                      ;;
                    --to-mounted-system=*)
                      mounted_system_prefix="''${1#*=}"
                      shift
                      ;;
                    -t)
                      if [ "$#" -ge 2 ] && [ "''${2#-}" = "$2" ]; then
                        mounted_system_prefix="$2"
                        shift 2
                      else
                        mounted_system_prefix="/mnt"
                        shift
                      fi
                      ;;
                    -h|--help)
                      usage
                      exit 0
                      ;;
                    *)
                      printf 'Unknown argument: %s\n\n' "$1" >&2
                      usage >&2
                      exit 1
                      ;;
                  esac
                done

                        real_user="''${SUDO_USER:-$USER}"
                        real_home="$(getent passwd "$real_user" | cut -d: -f6)"
                        real_group="$(id -gn "$real_user")"

                        if [ -n "$key_file_override" ] && [ -n "$key_value_override" ]; then
                          printf 'Use only one of --from-file or --from-value\n' >&2
                          exit 1
                        fi

                        if [ -z "$real_home" ]; then
                          printf 'Unable to determine home directory for user %s\n' "$real_user" >&2
                          exit 1
                        fi

                        host_name="$(hostnamectl --static 2>/dev/null || hostname)"
                        key_label="''${key_label_override:-''${SETUP_AGE_KEY_LABEL:-$host_name.s}}"
                        mount_point="''${mount_point_override:-''${SETUP_AGE_KEY_MOUNT_POINT:-/media/key}}"
                        temp_key_file=""

                        cleanup() {
                          if [ -n "$temp_key_file" ] && [ -f "$temp_key_file" ]; then
                            rm -f "$temp_key_file"
                          fi
                        }
                        trap cleanup EXIT

                        if [ -n "$key_value_override" ]; then
                          temp_key_file="$(mktemp)"
                          chmod 600 "$temp_key_file"
                          printf '%s\n' "$key_value_override" > "$temp_key_file"
                          key_path="$temp_key_file"
                        elif [ -n "$key_file_override" ]; then
                          if [ ! -f "$key_file_override" ]; then
                            printf 'Key file not found: %s\n' "$key_file_override" >&2
                            exit 1
                          fi
                          key_path="$key_file_override"
                        else
                          if ! mountpoint -q "$mount_point"; then
                            if [ ! -e "/dev/disk/by-label/$key_label" ]; then
                              printf 'Expected key USB at /dev/disk/by-label/%s but it was not found.\n' "$key_label" >&2
                              exit 1
                            fi

                            sudo mkdir -p "$mount_point"
                            sudo mount -t exfat -o ro,umask=0077 "/dev/disk/by-label/$key_label" "$mount_point"
                          fi

                          key_path=""
                          for candidate in \
                            "$mount_point/key.txt" \
                            "$mount_point/shared-age-key.txt" \
                            "$mount_point/sops-age-key.txt" \
                            "$mount_point/.secrets.key"
                          do
                            if [ -f "$candidate" ]; then
                              key_path="$candidate"
                              break
                            fi
                          done

                          if [ -z "$key_path" ]; then
                            printf 'No age key file found on %s. Checked: key.txt, shared-age-key.txt, sops-age-key.txt, .secrets.key\n' "$mount_point" >&2
                            exit 1
                          fi
                        fi

                        install -d -m 700 "$real_home/.config/sops/age"
                install -m 600 "$key_path" "$real_home/.config/sops/age/keys.txt"
                chown "$real_user:$real_group" "$real_home/.config/sops/age/keys.txt"

                sudo mkdir -p /var/lib/sops-nix
                sudo install -m 0400 -o root -g root "$key_path" /var/lib/sops-nix/key.txt

                if [ -n "$mounted_system_prefix" ]; then
                  sudo mkdir -p "$mounted_system_prefix/var/lib/sops-nix"
                  sudo install -m 0400 -o root -g root "$key_path" "$mounted_system_prefix/var/lib/sops-nix/key.txt"
                fi

                printf 'Installed age key for user %s and /var/lib/sops-nix/key.txt\n' "$real_user"
                if [ -n "$mounted_system_prefix" ]; then
                  printf 'Installed age key into mounted system at %s/var/lib/sops-nix/key.txt\n' "$mounted_system_prefix"
                fi
      '';
    };
  in {
    packages.bootstrapAge = setupAgeKey;
    packages.setupAgeKey = setupAgeKey;

    apps.bootstrapAge = {
      type = "app";
      program = lib.getExe self'.packages.bootstrapAge;
    };

    apps.setupAgeKey = {
      type = "app";
      program = lib.getExe self'.packages.setupAgeKey;
    };
  };
}
