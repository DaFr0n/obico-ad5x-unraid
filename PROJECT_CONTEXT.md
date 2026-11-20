# Obico AD5X / ZMOD Community Package — Project Context

## Purpose

This package preserves the custom compatibility work required to run a self-hosted Obico installation on Unraid with a FlashForge AD5X printer running ZMOD.

It is a compatibility layer around the upstream projects. It is **not** an official Obico, FlashForge, ZMOD, or Unraid project.

The package is intended to provide:

- recovery material if the working installation is lost;
- the custom patches used by the current known-good installation;
- Unraid Docker templates;
- installation and verification scripts;
- configuration examples;
- enough technical context to continue development safely in a future session.

## Current Target

Primary environment:

- Unraid
- FlashForge AD5X
- ZMOD firmware/software
- Self-hosted Obico
- Moonraker-Obico
- Coturn TURN server
- Redis

Expected Docker containers:

- `obico`
- `moonraker-obico`
- `obico-turn`

## Current Images

The known-good installation uses:

### Obico Server

```text
ghcr.io/imagegenius/obico:latest
```

The container uses the custom entrypoint:

```text
/config/turn-patch/entrypoint.sh
```

### Moonraker-Obico

```text
ghcr.io/thespaghettidetective/moonraker-obico:latest
```

The container uses:

```text
/zmod-entrypoint.sh
```

### Coturn

```text
coturn/coturn:latest
```

Coturn is run using host networking.

## Why the Moonraker-Obico Patch Exists

The AD5X/ZMOD Moonraker configuration does not use the API-key authentication expected by the standard Moonraker-Obico client.

The ZMOD startup wrapper therefore patches the upstream Moonraker-Obico installation at container startup.

The compatibility wrapper:

1. checks that the expected upstream source files exist;
2. disables automatic `self.ensure_api_key()`;
3. disables the Moonraker websocket `X-Api-Key` header;
4. installs the persistent TURN-related Python files;
5. starts the normal upstream Docker entrypoint.

Important patch locations:

```text
moonraker-obico/zmod-entrypoint.sh
moonraker-obico/webcam_stream.py
moonraker-obico/janus_config_builder.py
```

The live container currently verifies the important changes with:

```text
# ZMOD PATCH: self.ensure_api_key()
```

and:

```text
turn=self.linked_printer.get('turn')
```

and:

```text
bandwidth_throttle = 0.0005
```

## Moonraker-Obico Mount Layout

Known-good live layout:

```text
/mnt/cache/appdata/moonraker-obico/patch/zmod-entrypoint.sh
    -> /zmod-entrypoint.sh          [ro]

/mnt/cache/appdata/moonraker-obico/patch
    -> /zmod-patch                   [ro]

/mnt/cache/appdata/moonraker-obico/config
    -> /opt/printer_data/config      [rw]

/mnt/cache/appdata/moonraker-obico/logs
    -> /opt/printer_data/logs        [rw]
```

The obsolete direct TURN config mount into Moonraker-Obico was removed.

The current package does **not** rely on a separate:

```text
/opt/obico-turn/turnserver.conf
```

mount inside Moonraker-Obico.

## Obico Server TURN Patch

The Obico server has a custom entrypoint:

```text
obico/entrypoint.sh
```

It installs these compatibility files into the running ImageGenius Obico container:

```text
settings.py
context_processors.py
octoprint_views.py
turn.py
```

It also installs the bundled frontend build.

The live container uses:

```text
/config/turn-patch
```

for these files.

The frontend build is required because the server-side TURN configuration is exposed to the WebRTC frontend.

## TURN Upstream Basis

The Obico server TURN implementation corresponds exactly to upstream Obico PR #1157:

Title:

```text
Server-side TURN configuration for WebRTC webcam streaming
```

Commit:

```text
23792950dfe52326c0d129811dfc14c736a9e4c0
```

The eight critical files compared against that exact commit matched byte-for-byte during validation.

The implementation supports TURN configuration being supplied to authenticated clients/printer agents and supports shared-secret credentials.

The upstream PR was checked directly rather than assuming the local snapshot was equivalent.

## Moonraker-Obico TURN Upstream Basis

The TURN-agent functionality is based on upstream Moonraker-Obico PR #130:

```text
Use the TURN server configured on obico-server
```

The package retains the required compatibility files because the installed upstream container may not yet provide the required behaviour in the version being used.

## Coturn

Coturn is used without modification.

Known-good configuration characteristics:

```text
listening-port=3478
use-auth-secret
static-auth-secret=<private 64-character secret>
min-port=49160
max-port=49200
```

The actual TURN secret is deliberately excluded from this package.

The same secret must be supplied to:

```text
turnserver.conf
```

and the Obico container's:

```text
TURN_SECRET
```

environment variable.

The two values must match exactly.

The package includes:

```text
scripts/generate-turn-secret.sh
```

which generates a new 64-character hexadecimal secret using:

```text
openssl rand -hex 32
```

## Secrets and Private State

The package deliberately does **not** contain:

- TURN secret;
- `turn-secret.txt`;
- Moonraker-Obico printer authentication token;
- Obico database;
- Redis credentials;
- private runtime configuration;
- installation-specific LAN IP addresses;
- installation-specific public IP addresses;
- logs;
- Docker volumes.

These must remain outside any public/community distribution.

A private backup should separately preserve:

```text
/mnt/cache/appdata/obico/
/mnt/cache/appdata/moonraker-obico/
/mnt/cache/appdata/obico-turn/
```

if full disaster recovery is required.

## Important Recovery Rule

Do not blindly overwrite an existing working installation.

The installer is designed to stop when it detects existing sensitive configuration such as:

```text
/mnt/cache/appdata/obico-turn/turnserver.conf
/mnt/cache/appdata/moonraker-obico/config/moonraker-obico.cfg
```

Preserve existing working configuration before performing recovery work.

## Known Package Contents

The intended package contains:

```text
README.md
RESTORE_README.md
UPSTREAM.md
PROJECT_CONTEXT.md
VERSION
.gitignore

config-examples/
    moonraker-obico.cfg.example
    turnserver.conf.example

moonraker-obico/
    janus_config_builder.py
    webcam_stream.py
    zmod-entrypoint.sh

obico/
    context_processors.py
    entrypoint.sh
    octoprint_views.py
    settings.py
    turn.py
    frontend-build/

scripts/
    generate-turn-secret.sh
    install.sh
    verify.sh

templates/
    Moonraker-Obico-AD5X.xml
    Obico-AD5X.xml
    Obico-TURN.xml
```

No upstream full-source snapshot is required for normal recovery.

## Future Code Changes

When investigating a future failure after an upstream Docker image update:

1. Identify the exact image/tag currently running.
2. Compare the expected upstream source file/function against the patch.
3. Do not assume line numbers remain valid.
4. Check whether the upstream project has incorporated the required functionality.
5. Check the relevant upstream PR/commit before changing the local patch.
6. Preserve the ZMOD compatibility requirement separately from TURN functionality.
7. Validate the running container after changing a patch.
8. Update this package if the known-good implementation changes.

The most important files to review first are:

```text
moonraker-obico/zmod-entrypoint.sh
moonraker-obico/webcam_stream.py
moonraker-obico/janus_config_builder.py

obico/entrypoint.sh
obico/settings.py
obico/context_processors.py
obico/octoprint_views.py
obico/turn.py
```

## Validation

The package should pass:

- shell syntax checks;
- XML well-formedness checks;
- private IP/secret audits;
- required-file checks;
- backup/temporary-file checks.

The package should not contain installation-specific credentials or private runtime state.

## Licensing / Attribution

The package contains modified/copied source files derived from upstream open-source projects.

The upstream project licences and attribution notices must be retained where applicable.

Relevant upstream projects:

- TheSpaghettiDetective / Obico Server
- TheSpaghettiDetective / Moonraker-Obico
- Coturn

The package is intended to preserve attribution and provide the relevant upstream references rather than present upstream code as original work.

See `UPSTREAM.md` for the upstream project and PR references.

## Current Status

Status:

```text
Known-good
```

Target:

```text
Unraid + FlashForge AD5X + ZMOD + self-hosted Obico + Moonraker-Obico + Coturn
```

Package role:

```text
Recovery / reproducibility / future development reference
```

It is not required for the running containers once the compatibility files have been installed into their appdata directories.

## Change History

### Initial known-good package

Date:

```text
2026-09-27
```

Major components:

- ZMOD Moonraker authentication compatibility;
- Moonraker-Obico TURN integration;
- Obico server-side TURN integration;
- Coturn configuration;
- Unraid templates;
- installer;
- verification script;
- recovery documentation.

The package was intentionally reduced from an earlier development snapshot by removing the full upstream Obico source tree and troubleshooting/backup files. The final package was approximately 33 MB.
