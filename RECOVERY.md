# Obico AD5X/ZMOD Recovery

## Purpose

`restore.sh` rebuilds the package-managed Obico, Moonraker-Obico and Coturn
configuration files from this known-good package.

It does **not** create, delete, stop, or modify Docker containers.

## Run

From this package directory as Unraid root:

```bash
bash scripts/restore.sh
```

The script asks for:

- Unraid LAN IPv4 address
- Public IPv4 address
- AD5X/ZMOD IPv4 address
- Obico server IP

It generates a new 64-character TURN secret and stores it in:

```text
/mnt/cache/appdata/obico-turn/turn-secret.txt
```

It deliberately refuses to overwrite existing TURN or Moonraker-Obico
configuration.

## Important

This package does not contain:

- Obico database/user data
- printer authentication tokens
- live TURN secrets
- live logs/timelapses
- installation-specific configuration

Those must be backed up separately if a complete application-state recovery
is required.

After restoring the files, install/start the supplied Unraid Docker templates
and run `scripts/verify.sh`.
