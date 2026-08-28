[English](README.md) | [Français](README.fr.md)

# nixconfig

Flake NixOS de Sacha.

## Structure

```text
.
├── flake.nix
├── hosts/        # host entrypoints, hardware modules, disko configs
├── modules/      # reusable NixOS modules and aggregate modules
├── options/      # flake-parts output/options helpers
├── packages/     # wrapped packages, dev shells, formatter, custom packages
├── services/     # homelab service modules
├── lib/          # local flake library helpers
└── secrets.nix   # agenix recipient rules
```

`flake.nix` importe chaque fichier `*.mod.nix` comme module `flake-parts`. Les fichiers de module NixOS standard doivent donc être exportés avec `flake.nixosModules.<name>`.

## Hôtes

Sorties d'hôtes actuelles :

```bash
nix flake show 'path:/home/sacha/Projects/nixconfig'
```

Hôtes principaux :

```text
house-desktop
house-laptop
homelab
wsl
```

Les fichiers d'hôtes restent volontairement courts. Ils importent des modules agrégés comme `workstation`, `desktop`, `hyprland`, `niri`, `gaming` ou `homelab`, puis définissent le matériel et les préférences de l'hôte.

## Configuration initiale

Clonez le dépôt à l'emplacement attendu par la configuration :

```bash
mkdir -p /home/sacha/Projects
git clone git@github.com:sachahjkl/nixconfig.git /home/sacha/Projects/nixconfig
cd /home/sacha/Projects/nixconfig
```

Si l'hôte utilise des secrets agenix, restaurez la clé privée agenix dédiée depuis Bitwarden :

```bash
install -m 700 -d ~/.ssh
$EDITOR ~/.ssh/agenix
chmod 600 ~/.ssh/agenix
```

La clé publique est déclarée dans `modules/keys.mod.nix`. N'utilisez pas la clé SSH résidente `sk-*` de la YubiKey pour agenix. Agenix nécessite une clé SSH normale qui autorise le déchiffrement.

Si l'hôte utilise des secrets `sops-nix`, conservez la même clé privée age à deux emplacements :

1. Une copie utilisateur sert à modifier les fichiers chiffrés de manière interactive avec `sops`.
2. Une copie de l'hôte détenue par root sert au déchiffrement lors de l'activation avec `sops-nix`.

Placez la copie utilisateur ici :

```bash
mkdir -p ~/.config/sops/age
install -m 600 /path/to/shared-age-key.txt ~/.config/sops/age/keys.txt
```

Par défaut, `sops` cherche dans `~/.config/sops/age/keys.txt`. Ce dépôt crée `~/.config/sops/age` pour l'utilisateur principal et conserve `.config/sops`. La clé survit donc aux reconstructions et redémarrages normaux des hôtes conservés.

Placez ici la copie de l'hôte détenue par root :

```bash
sudo mkdir -p /var/lib/sops-nix
sudo install -m 0400 -o root -g root /path/to/shared-age-key.txt /var/lib/sops-nix/key.txt
```

`sops-nix` utilise `/var/lib/sops-nix/key.txt` pendant l'activation. Il déchiffre les secrets d'exécution comme les empreintes de mots de passe, les clés d'authentification Tailscale et les identifiants de services. `/var/lib/sops-nix` appartient à l'ensemble partagé de conservation. La clé survit donc aux redémarrages et reconstructions normaux des hôtes conservés.

Ce dépôt fournit aussi une application auxiliaire qui installe les deux copies :

```bash
nix run .#bootstrapAge
```

Par défaut, elle attend le libellé USB secret `<hostname>.s` et le monte sur `/media/key` si nécessaire. Elle cherche `key.txt`, `shared-age-key.txt`, `sops-age-key.txt` ou `.secrets.key`, puis installe la clé aux deux emplacements suivants :

```text
~/.config/sops/age/keys.txt
/var/lib/sops-nix/key.txt
```

Elle accepte aussi des sources explicites :

```bash
nix run .#bootstrapAge -- --from-file /path/to/shared-age-key.txt
nix run .#bootstrapAge -- --from-value 'AGE-SECRET-KEY-...'
```

Autres options utiles :

```bash
nix run .#bootstrapAge -- --label homelab.s
nix run .#bootstrapAge -- --to-mounted-system
nix run .#bootstrapAge -- --to-mounted-system=/mnt/some-other-root
nix run .#bootstrapAge -- --help
```

`--to-mounted-system` sert depuis l'image ISO autonome NixOS après le montage de la racine cible par `disko`. L'option installe aussi la copie d'activation dans `<target>/var/lib/sops-nix/key.txt`. Vous pouvez ainsi exécuter `nixos-install` sans copier d'abord la clé dans `/mnt`.

Les secrets chiffrés partagés et propres aux hôtes se trouvent maintenant dans :

```text
secrets/shared.yaml
secrets/homelab.yaml
```

Modifiez-les avec :

```bash
nix shell nixpkgs#sops -c sops secrets/shared.yaml
nix shell nixpkgs#sops -c sops secrets/homelab.yaml
```

Procédure normale :

1. Ouvrez le fichier chiffré concerné avec `sops`.
2. Modifiez les valeurs en clair dans votre éditeur.
3. Enregistrez et quittez. `sops` chiffre à nouveau le fichier sur place.
4. Reconstruisez l'hôte pour que `sops-nix` actualise les secrets d'exécution.

Répartition actuelle :

- `secrets/shared.yaml` : secrets partagés entre les hôtes, comme `shared.password-hash` et `tailscale.user-authkey`.
- `secrets/homelab.yaml` : secrets propres au homelab, comme `tailscale.server-authkey`, `restic.password` et `restic.environment`.

Pour consulter le contenu déchiffré sans le modifier :

```bash
nix shell nixpkgs#sops -c sops decrypt secrets/shared.yaml
nix shell nixpkgs#sops -c sops decrypt secrets/homelab.yaml
```

Après une modification des secrets, appliquez-les avec votre procédure de reconstruction habituelle. Par exemple :

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#homelab
```

## Exécuteur GitHub Actions

Le module homelab fournit des exécuteurs GitHub Actions désactivés sous `homelab.services.githubRunner`.

GitHub ne prend pas en charge les exécuteurs de compte pour les comptes personnels. Le module enregistre une instance d'exécuteur pour chaque dépôt configuré.

Créez un PAT précis dédié avec l'accès aux exécuteurs de tous les dépôts configurés. Ajoutez-le comme `github.actions-runner` dans `secrets/homelab.yaml` :

```bash
nix shell nixpkgs#sops -c sops secrets/homelab.yaml
```

Activez les exécuteurs sur `homelab` après la création des URLs des dépôts et du PAT chiffré :

```nix
homelab.services.githubRunner = {
  enable = true;
  repositories = {
    git-migrate = "https://github.com/owner/git-migrate";
    nixconfig = "https://github.com/owner/nixconfig";
  };
};
```

Chaque service utilise l'utilisateur système `github-runner`. Il utilise journald et fournit les libellés par défaut `self-hosted`, `linux` et `x64`.

Le module ajoute aussi `nixos`, `nix` et `homelab`. Les workflows peuvent le sélectionner avec `runs-on: [self-hosted, nixos]`.

Après le déploiement, vérifiez le service et l'accès à Nix :

```bash
systemctl status github-runner-git-migrate
journalctl -u github-runner-git-migrate
sudo -u github-runner nix --version
```

Utilisez un workflow manuel dans le dépôt enregistré pour tester l'attribution des tâches :

```yaml
name: Homelab runner test
on:
  workflow_dispatch:
jobs:
  check:
    runs-on: [self-hosted, nixos]
    steps:
      - uses: actions/checkout@v4
      - run: nix --version
      - run: nix flake check
```

## Observabilité

Le module `homelabObservability` déploie les services suivants dans Docker :

- OpenTelemetry Collector reçoit les traces, les journaux et les métriques OTLP.
- Loki conserve les journaux pendant 30 jours.
- Tempo conserve les traces pendant 14 jours.
- Prometheus conserve les métriques pendant 30 jours, avec une limite de 20 Go.
- Grafana fournit les sources Prometheus, Loki et Tempo préconfigurées.

Les données résident dans `/data/Docker/appdata/observability`.

Le service Restic sauvegarde déjà ce répertoire par son parent `/data/Docker/appdata`.

Les domaines se configurent dans `hosts/homelab/homelab.mod.nix` :

```nix
homelab.services.observability = {
  enable = true;
  grafanaDomain = "grafana.sacha.house";
  otlpDomain = "otlp.sacha.house";
};
```

Utilisez `admin` comme identifiant Grafana.

Déchiffrez le mot de passe Grafana avec cette commande :

```bash
sops decrypt --extract '["observability"]["grafana-environment"]' secrets/homelab.yaml
```

Configurez Froment avec ces variables :

```text
OTEL_TRACES_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.sacha.house
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic%20<identifiants-base64>
DEPLOYMENT_ENVIRONMENT=production
```

Générez les identifiants Base64 sans écrire le mot de passe sur le disque :

```bash
OTLP_PASSWORD="$(sops decrypt --extract '["observability"]["otlp-password"]' secrets/homelab.yaml)"
printf 'froment:%s' "$OTLP_PASSWORD" | base64 -w0
unset OTLP_PASSWORD
```

Le proxy accepte OTLP/HTTP avec protobuf sur `/v1/traces`, `/v1/logs` et `/v1/metrics`.

Appliquez la configuration avec la procédure de reconstruction habituelle.

## Reconstruction

Méthode recommandée :

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
```

Méthode directe :

```bash
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#house-desktop
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#house-laptop
```

## Nouvelle installation

Démarrez une image ISO NixOS, clonez le dépôt, puis exécutez la configuration disko de l'hôte.

Attention : disko détruit les données. Vérifiez le disque cible dans `hosts/<host>/disko.mod.nix` avant de l'exécuter.

### En bref : installation de `homelab` depuis l'image ISO NixOS

```bash
mkdir -p /home/nixos/Projects
git clone git@github.com:sachahjkl/nixconfig.git /home/nixos/Projects/nixconfig
cd /home/nixos/Projects/nixconfig
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake 'path:/home/nixos/Projects/nixconfig#homelab'
nix run .#bootstrapAge -- --to-mounted-system
sudo nixos-install --root /mnt --flake 'path:/home/nixos/Projects/nixconfig#homelab'
reboot
cd /data/Home/sacha/Projects/nixconfig
nix run .#bootstrapAge
sudo nixos-rebuild switch --flake /data/Home/sacha/Projects/nixconfig#homelab
```

Le premier appel à `bootstrapAge` depuis l'image ISO place la clé d'activation dans `/mnt/var/lib/sops-nix/key.txt`. `nixos-install` peut ainsi déchiffrer les secrets. Le second appel après le redémarrage installe aussi la clé pour les modifications normales de l'utilisateur.

Pour les systèmes chiffrés ou FIDO2, conservez au moins une phrase secrète de récupération. Vérifiez le déverrouillage par YubiKey avant l'installation.

## Démarrage sécurisé

Cette configuration utilise Limine avec la prise en charge du démarrage sécurisé. La configuration initiale nécessite généralement la création et l'inscription manuelles des clés.

Créez les clés :

```bash
nix shell nixpkgs#sbctl
sudo sbctl create-keys
```

Après le premier démarrage réussi, inscrivez les clés tout en conservant les certificats Microsoft :

```bash
sudo sbctl enroll-keys --microsoft
```

Si nécessaire, vérifiez et signez les binaires EFI de Limine :

```bash
sudo sbctl status
sudo sbctl verify
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
```

## Vérification

Utilisez `path:` pour inclure les fichiers non suivis pendant le développement :

```bash
nix flake check 'path:/home/sacha/Projects/nixconfig' --no-write-lock-file
```

Compilez un hôte sans l'activer :

```bash
nix build 'path:/home/sacha/Projects/nixconfig#nixosConfigurations.house-desktop.config.system.build.toplevel' --dry-run
```

## Mise à jour d'Opencode

`opencode` est fixé par l'entrée de flake `opencode-src`.

Pour le mettre à jour, modifiez `flake.nix` avec la balise voulue. Par exemple :

```nix
opencode-src.url = "github:anomalyco/opencode/v1.17.3";
```

Actualisez ensuite le verrou et compilez une fois :

```bash
nix flake update opencode-src
nix build 'path:/home/sacha/Projects/nixconfig#opencode' --no-link
```

Si Nix signale une différence d'empreinte `node_modules`, copiez l'empreinte `got:` signalée dans `packages/opencode/opencode.mod.nix`.
