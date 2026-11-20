# Obico AD5X / ZMOD Restore Guide

This document explains how to restore the Obico AD5X / ZMOD community package on Unraid.

The package is designed to restore the compatibility files and configuration structure used by:

- Obico Server
- Moonraker-Obico
- Coturn
- FlashForge AD5X running ZMOD

It does **not** contain your personal Obico database, printer authentication token, TURN secret, Redis data, or other private runtime state.

## Before You Restore

Make sure the package has been copied to a location accessible from Unraid, for example:

```text
/mnt/user/David/unRAID/Community Apps/Obico My Version
```

Run the restore as `root`.

The restore script is deliberately designed not to overwrite an existing working configuration without warning.

## Restore Script

Run:

```bash
cd "/mnt/user/David/unRAID/Community Apps/Obico My Version"
bash scripts/restore.sh
```

Follow the prompts provided by the script.

## What Is Restored

The package contains the compatibility components required for the installation:

### Moonraker-Obico

Restores:

```text
/mnt/cache/appdata/moonraker-obico/patch/zmod-entrypoint.sh
/mnt/cache/appdata/moonraker-obico/patch/webcam_stream.py
/mnt/cache/appdata/moonraker-obico/patch/janus_config_builder.py
```

It also recreates the required directory structure:

```text
/mnt/cache/appdata/moonraker-obico/config
/mnt/cache/appdata/moonraker-obico/logs
/mnt/cache/appdata/moonraker-obico/patch
```

### Obico Server TURN Support

Restores the TURN compatibility patch under:

```text
/mnt/cache/appdata/obico/turn-patch/
```

This includes the backend patch files and the bundled frontend build required by the custom Obico entrypoint.

### Coturn

The restore process can recreate the Coturn configuration structure.

A new TURN secret must be generated if the original secret is unavailable.

## Important: TURN Secret

The TURN secret is intentionally **not stored in the community package**.

This prevents a private authentication secret from being distributed with the package.

If you are restoring an existing installation and still have the original secret, use that same secret for:

```text
/mnt/cache/appdata/obico-turn/turnserver.conf
```

and the Obico container's:

```text
TURN_SECRET
```

environment variable.

These values must match exactly.

If the original secret has been lost, generate a new one and update both sides.

After changing the secret, restart the relevant containers.

## Important: Moonraker Authentication Token

The linked printer's Obico authentication token is also **not stored in the package**.

The restored configuration contains a placeholder:

```text
PASTE_LINKED_PRINTER_AUTH_TOKEN_HERE
```

Replace this with the authentication token for the linked printer in:

```text
/mnt/cache/appdata/moonraker-obico/config/moonraker-obico.cfg
```

Do not publish the real token.

## Docker Containers

The restore script restores the files used by the containers. It does not intentionally create, delete, stop, or modify Docker containers.

The expected containers are:

```text
obico
moonraker-obico
obico-turn
```

The Unraid Docker templates are included in:

```text
templates/
```

Install/configure the templates through Unraid's Docker interface.

## Network Configuration

The installation requires the appropriate network configuration for your environment.

The standard TURN ports used by this package are:

```text
UDP 3478
TCP 3478
UDP 49160-49200
```

The relay range must be forwarded to the Unraid host if TURN traffic needs to reach the server from outside the LAN.

Do not blindly reuse the example IP addresses. Enter the IP addresses belonging to the installation being restored.

## Redis

The Obico server requires Redis.

The Redis address used by the original installation is installation-specific and is therefore not stored as live configuration in the public package.

Configure the Obico container's Redis connection for the Redis instance being used on the restored Unraid system.

## Recovery After a Complete Loss

If the original `/mnt/cache/appdata` data has been lost completely:

1. Copy the community package back to Unraid.
2. Run `scripts/restore.sh`.
3. Install/configure Redis.
4. Install/configure the Obico container.
5. Install/configure Coturn.
6. Configure the TURN secret.
7. Configure the Obico server IP.
8. Configure the AD5X/ZMOD printer IP.
9. Restore the linked printer's Obico authentication token.
10. Install/start Moonraker-Obico.
11. Start Obico and Coturn.
12. Verify the printer connection.
13. Test webcam/WebRTC streaming.

## Recovery of an Existing Installation

If the Docker containers and appdata still exist, do **not** blindly run the restore process over them.

First preserve the existing configuration.

In particular, retain:

```text
/mnt/cache/appdata/obico/
/mnt/cache/appdata/moonraker-obico/
/mnt/cache/appdata/obico-turn/
```

The package is intended to provide the compatibility files needed to rebuild the installation, not to replace private runtime data.

## Security

Never publish:

- `TURN_SECRET`
- `turn-secret.txt`
- Obico printer authentication tokens
- Obico database files
- Redis credentials
- private configuration files containing credentials
- personal/public IP addresses if you do not want them disclosed

The community package intentionally uses placeholders instead of the live values from the original installation.

## Verification

After restoring, run the package verification script:

```bash
bash scripts/verify.sh
```

Then verify the containers and patches.

For Moonraker-Obico, the important compatibility patches should be present in the running container.

For Obico, verify that the TURN patch is loaded.

For Coturn, verify that port `3478` and the configured relay range are listening.

## Recovery Philosophy

The package is a **reproducible compatibility package**, not a backup of private application state.

It contains the files required to recreate the custom AD5X/ZMOD integration while deliberately leaving private credentials and runtime data outside the distributable package.

For a complete disaster-recovery setup, keep a separate private backup of:

```text
/mnt/cache/appdata/obico/
/mnt/cache/appdata/moonraker-obico/
/mnt/cache/appdata/obico-turn/
```

That private backup should never be uploaded to a public repository or Community Applications package.
