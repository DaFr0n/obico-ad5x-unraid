# Upstream Projects and Patch Sources

This project packages compatibility changes for running a self-hosted Obico
installation on Unraid with FlashForge AD5X printers running ZMOD.

It is not an official Obico, FlashForge, ZMOD, or Unraid project.

## Obico Server

Upstream:
https://github.com/TheSpaghettiDetective/obico-server

Self-hosted TURN support is based on upstream work:

PR #1157
"Server-side TURN configuration for WebRTC webcam streaming"

https://github.com/TheSpaghettiDetective/obico-server/pull/1157

## moonraker-obico

Upstream:
https://github.com/TheSpaghettiDetective/moonraker-obico

TURN-agent support is based on:

PR #130
"Use the TURN server configured on obico-server"

https://github.com/TheSpaghettiDetective/moonraker-obico/pull/130

## Coturn

Upstream:
https://github.com/coturn/coturn

The official coturn Docker image is used without modification.

## AD5X / ZMOD compatibility

The moonraker-obico startup wrapper additionally works around the AD5X/ZMOD
Moonraker configuration where API-key authentication is disabled.

No modification to the printer, Klipper, Moonraker or ZMOD installation is
required by this package.
