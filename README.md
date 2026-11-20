# Obico Self-Hosted for FlashForge AD5X + ZMOD on Unraid

Community compatibility package for running a self-hosted Obico installation
with a FlashForge AD5X running [ZMOD](https://github.com/ghzserg/zmod), using
Unraid Docker containers.

This project provides:

- AD5X/ZMOD compatibility for [Moonraker-Obico](https://github.com/TheSpaghettiDetective/moonraker-obico)
- Self-hosted TURN support for [Obico Server](https://github.com/TheSpaghettiDetective/obico-server) WebRTC
- [Coturn](https://github.com/coturn/coturn) configuration examples
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

Moonraker-Obico normally obtains a Moonraker API key and subsequently sends it
with its requests. On this configuration Moonraker rejects the supplied key.

The included startup wrapper disables API-key acquisition and the X-Api-Key
WebSocket header without modifying the printer.

### 2. Self-hosted WebRTC TURN

The self-hosted TURN implementation in this package is based on proposed
upstream changes that have not yet been merged into the official projects:

- [Obico Server PR #1157 — Server-side TURN configuration for WebRTC webcam streaming](https://github.com/TheSpaghettiDetective/obico-server/pull/1157)
- [Moonraker-Obico PR #130 — Use the TURN server configured on obico-server](https://github.com/TheSpaghettiDetective/moonraker-obico/pull/130)

Both pull requests were still open and unmerged when this package was reviewed
on 20 November 2026. This repository carries the compatibility files needed
for the tested installation; it does not imply that these changes are part of
the current official releases.

A local [Coturn](https://github.com/coturn/coturn) container provides the TURN
relay.

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

## Containers and original projects

The tested installation uses:

- Obico Server container: [ImageGenius docker-obico](https://github.com/imagegenius/docker-obico)
  - Application source: [TheSpaghettiDetective/obico-server](https://github.com/TheSpaghettiDetective/obico-server)
- Moonraker client: [TheSpaghettiDetective/moonraker-obico](https://github.com/TheSpaghettiDetective/moonraker-obico)
- TURN relay: [Coturn](https://github.com/coturn/coturn)
- Printer firmware modification: [ZMOD](https://github.com/ghzserg/zmod)

The ImageGenius repository builds the Obico Docker image used by this package;
it is separate from the upstream Obico Server application repository.

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

See [config-examples/turnserver.conf.example](config-examples/turnserver.conf.example).

## Coturn external IP

Coturn must know both the public Internet IPv4 address and the LAN address of
the Unraid server:

    external-ip=YOUR_PUBLIC_IPV4/YOUR_UNRAID_IP

If the public IPv4 address changes, this value must be updated and Coturn
restarted.

This is particularly important for Internet WebRTC connectivity.

## moonraker-obico configuration

Copy
[config-examples/moonraker-obico.cfg.example](config-examples/moonraker-obico.cfg.example)
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

Because this project currently relies on compatibility patches taken from
unmerged upstream pull requests and on specific upstream container layouts,
test container updates before relying on them. The upstream PRs may change,
be closed, or be merged differently. Re-check their status before removing
any local patches.

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

The `templates` directory contains development copies exported from Unraid
dockerMan. They have not been certified as Community Applications templates.

Review and test them through Unraid dockerMan before submitting them to
Community Applications. Replace example values with the values for the target
installation.

## Upstream projects, source and attribution

See [UPSTREAM.md](UPSTREAM.md) for the original projects, the exact pull
requests/commits used as patch sources, and the current upstream status.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for third-party code and
licensing information.

## Status

Initial community package: experimental.

Known working environment:

- FlashForge AD5X
- ZMOD
- Unraid
- self-hosted Obico
- Moonraker-Obico
- Coturn
- MJPEG WebRTC camera streaming
