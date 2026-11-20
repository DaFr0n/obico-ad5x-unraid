# Third-party notices

This repository contains compatibility files derived from upstream
open-source projects. It is not an official release of any of those projects.

## Obico Server — AGPL-3.0

Original project: https://github.com/TheSpaghettiDetective/obico-server

Relevant proposed TURN implementation:
https://github.com/TheSpaghettiDetective/obico-server/pull/1157

Patch source commit:
https://github.com/ddm-j/obico-server/commit/23792950dfe52326c0d129811dfc14c736a9e4c0

Files in this repository derived from the Obico Server PR implementation:

- `obico/settings.py`
- `obico/context_processors.py`
- `obico/octoprint_views.py`
- `obico/turn.py`
- `obico/frontend-build/`

The backend files are adapted/copied from the proposed PR implementation.
The frontend build is the compiled frontend output corresponding to that
implementation. The local `obico/entrypoint.sh` is a community-written
container integration script that installs these files into the ImageGenius
Obico container.

## Moonraker-Obico — AGPL-3.0

Original project: https://github.com/TheSpaghettiDetective/moonraker-obico

Relevant proposed TURN implementation:
https://github.com/TheSpaghettiDetective/moonraker-obico/pull/130

Patch source commit:
https://github.com/ddm-j/moonraker-obico/commit/a497ffdd51388e382cab48f10fda83a0a1bc4959

Files in this repository derived from Moonraker-Obico:

- `moonraker-obico/webcam_stream.py`
- `moonraker-obico/janus_config_builder.py`

The local `moonraker-obico/zmod-entrypoint.sh` is a community-written
compatibility wrapper for the AD5X/ZMOD Moonraker configuration.

## Licence text

The upstream Obico Server and Moonraker-Obico repositories identify their
source as AGPL-3.0. A copy of the AGPL-3.0 licence text is included at
`LICENSES/AGPL-3.0.txt`. Retain the applicable upstream notices and this
attribution when redistributing the derived files.

This notice identifies the known upstream-derived portions; it does not
claim that ZMOD firmware, Coturn, the ImageGenius Docker image, or Unraid
are bundled as source code in this repository. ZMOD source and firmware are
not included.
