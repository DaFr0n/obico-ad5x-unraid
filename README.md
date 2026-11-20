# Obico Self-Hosted for FlashForge AD5X + ZMOD on Unraid

Community compatibility package for running a self-hosted Obico installation
with a FlashForge AD5X running ZMOD, using Unraid Docker containers.

This project provides:

- AD5X/ZMOD compatibility for moonraker-obico
- Self-hosted TURN support for Obico WebRTC
- Coturn configuration examples
- Persistent Unraid-friendly patches
- Improved MJPEG WebRTC performance for the AD5X camera
- Configuration examples and verification tools

This is an unofficial community project and is not affiliated with Obico,
FlashForge, ZMOD, Coturn or Unraid.

## Why is this needed?

Two compatibility issues are addressed.

### 1. AD5X/ZMOD Moonraker authentication

The AD5X/ZMOD Moonraker installation accepts unauthenticated local API
connections but has API-key authentication disabled.

moonraker-obico normally obtains a Moonraker API key and subsequently sends it
with its requests. On this configuration Moonraker rejects the supplied key.

The included startup wrapper disables API-key acquisition and the X-Api-Key
WebSocket header without modifying the printer.

### 2. Self-hosted WebRTC TURN

Current released Obico components do not yet contain the complete self-hosted
TURN configuration used by this installation.

The package incorporates compatibility work based on upstream Obico Server
PR #1157 and moonraker-obico PR #130.

A local Coturn container provides the TURN relay.

## Architecture

    AD5X / ZMOD
       |
       | Moonraker :7125
       |
       v
    moonraker-obico
       |
       | Obico API / WebRTC signalling
       |
       v
    Obico Server
       |
       | TURN credentials
       |
       v
    Coturn
       |
       | WebRTC relay
       |
       v
    Browser / Obico Client

No modifications to Klipper, Moonraker or ZMOD on the printer are required.

## Containers

The tested installation uses:

- ghcr.io/imagegenius/obico
- ghcr.io/thespaghettidetective/moonraker-obico
- coturn/coturn

## Persistent directories

Recommended Unraid locations:

    /mnt/cache/appdata/obico
    /mnt/cache/appdata/moonraker-obico
    /mnt/cache/appdata/obico-turn

The Docker containers themselves can therefore be recreated without losing
the persistent configuration.

## Network requirements

The Obico Web UI normally uses:

    TCP 3334

Coturn uses:

    UDP 3478
    TCP 3478
    UDP 49160-49200

For remote WebRTC access, forward the Coturn ports from the Internet router
to the Unraid server:

    UDP 3478        -> UNRAID_IP:3478
    TCP 3478        -> UNRAID_IP:3478
    UDP 49160-49200 -> UNRAID_IP:49160-49200

Do not forward these ports to the printer.

## TURN configuration

Generate a random TURN shared secret:

    ./scripts/generate-turn-secret.sh

Use exactly the same secret in:

1. Coturn:

       static-auth-secret=YOUR_SECRET

2. Obico environment:

       TURN_SECRET=YOUR_SECRET

The secret must never be committed to a public repository.

The Obico container also requires:

    TURN_SERVER=YOUR_UNRAID_IP
    TURN_PORT=3478
    TURN_TRANSPORTS=udp,tcp

See:

    config-examples/turnserver.conf.example

## Coturn external IP

Coturn must know both the public Internet IPv4 address and the LAN address of
the Unraid server:

    external-ip=YOUR_PUBLIC_IPV4/YOUR_UNRAID_IP

If the public IPv4 address changes, this value must be updated and Coturn
restarted.

This is particularly important for Internet WebRTC connectivity.

## moonraker-obico configuration

Copy:

    config-examples/moonraker-obico.cfg.example

to:

    /mnt/cache/appdata/moonraker-obico/config/moonraker-obico.cfg

Replace:

    YOUR_OBICO_SERVER_IP
    YOUR_AD5X_IP
    YOUR_LINKED_PRINTER_AUTH_TOKEN

with values appropriate to the installation.

Do not publish the resulting configuration because it contains the linked
printer authentication token.

## Webcam performance

The tested AD5X snapshot endpoint was capable of approximately 8-9 snapshots
per second.

The standard MJPEG WebRTC implementation introduced additional per-packet
delay which resulted in approximately 1-2 FPS on this setup.

The included tested patch changes:

    bandwidth_throttle = 0.004

to:

    bandwidth_throttle = 0.0005

On the tested AD5X this substantially improved WebRTC camera frame rate while
remaining below the camera/snapshot endpoint's practical limit.

## Updating containers

The startup wrappers apply the compatibility patches each time their
containers start.

The ZMOD compatibility wrapper deliberately checks for expected upstream code
before modifying it.

If an upstream image changes incompatibly, the wrapper should fail rather
than silently patch unexpected code.

Because this project currently relies on upstream compatibility patches,
test container updates before relying on them.

If the relevant upstream Obico changes are released officially, some patches
in this repository may no longer be necessary.

## Security

Never publish:

- TURN shared secrets
- Obico linked-printer authentication tokens
- Obico databases
- private application configuration
- other credentials from appdata

Example configuration files in this repository contain placeholders only.

## Verification

After installation run:

    ./scripts/verify.sh

The script checks the local Docker/container configuration and patch state.

A successful local verification does not by itself prove that router port
forwarding or remote NAT traversal is correctly configured. Final validation
should include opening the Obico WebRTC camera from outside the home network.

## Unraid templates

The `templates` directory currently contains development copies exported from
Unraid dockerMan.

Do not publish templates containing private IP-specific settings or secrets.

Community Applications-ready templates should be generated/tested through
Unraid dockerMan before submission.

## Upstream projects

See:

    UPSTREAM.md

for the upstream projects and pull requests on which this compatibility
package is based.

## Status

Initial community package: experimental.

Known working environment:

- FlashForge AD5X
- ZMOD
- Unraid
- self-hosted Obico
- moonraker-obico
- Coturn
- MJPEG WebRTC camera streaming

