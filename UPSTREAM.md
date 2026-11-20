# Upstream Projects, Patch Sources and Attribution

This project packages compatibility changes for running a self-hosted Obico
installation on Unraid with FlashForge AD5X printers running ZMOD.

It is an unofficial community project. It is not maintained by, endorsed by,
or affiliated with Obico, FlashForge, ZMOD, Coturn, ImageGenius or Unraid.

## Obico Server

- **Original application:** [TheSpaghettiDetective/obico-server](https://github.com/TheSpaghettiDetective/obico-server)
- **Docker image used:** [ImageGenius/docker-obico](https://github.com/imagegenius/docker-obico)
- **TURN feature patch source:** [PR #1157 — Server-side TURN configuration for WebRTC webcam streaming](https://github.com/TheSpaghettiDetective/obico-server/pull/1157)
- **PR author:** [ddm-j](https://github.com/ddm-j)
- **Patch head commit:** [23792950dfe52326c0d129811dfc14c736a9e4c0](https://github.com/ddm-j/obico-server/commit/23792950dfe52326c0d129811dfc14c736a9e4c0)

The Obico backend compatibility files and bundled frontend build in
`obico/` are based on that proposed PR implementation. The local entrypoint
copies the backend files into the ImageGenius container and installs the
corresponding frontend build.

**Upstream status checked 20 November 2026:** PR #1157 was open and unmerged.
It is a pull request against the upstream Obico Server project, not a merged
release feature. Re-check the PR and the ImageGenius image layout before
updating the local patch.

## Moonraker-Obico

- **Original project:** [TheSpaghettiDetective/moonraker-obico](https://github.com/TheSpaghettiDetective/moonraker-obico)
- **TURN-agent patch source:** [PR #130 — Use the TURN server configured on obico-server](https://github.com/TheSpaghettiDetective/moonraker-obico/pull/130)
- **PR author:** [ddm-j](https://github.com/ddm-j)
- **Patch head commit:** [a497ffdd51388e382cab48f10fda83a0a1bc4959](https://github.com/ddm-j/moonraker-obico/commit/a497ffdd51388e382cab48f10fda83a0a1bc4959)

The files in `moonraker-obico/` include the AD5X/ZMOD startup wrapper and
compatibility copies for webcam streaming and Janus TURN configuration. The
TURN-related code is based on the proposed PR implementation; the ZMOD
Moonraker API-key workaround is an additional community compatibility patch.

**Upstream status checked 20 November 2026:** PR #130 was open and unmerged.
The package therefore retains its local patch rather than assuming the
official Moonraker-Obico container already supports server-supplied TURN
configuration.

## ZMOD / FlashForge AD5X

- **ZMOD project and source:** [ghzserg/zmod](https://github.com/ghzserg/zmod)
- **ZMOD documentation:** [ZMOD documentation](https://ghzserg.github.io/)
- **AD5X documentation:** [AD5X guide](https://github.com/ghzserg/zmod/blob/main/docs/en/AD5X.md)

This package does not bundle or redistribute ZMOD firmware. It works around
the Moonraker API-key authentication configuration used by the target
AD5X/ZMOD installation. Check the ZMOD documentation and compatibility
notes for the printer's firmware version before making printer-side changes.

## ImageGenius Docker image

- **Docker image source:** [imagegenius/docker-obico](https://github.com/imagegenius/docker-obico)
- **Container package:** [ghcr.io/imagegenius/obico](https://github.com/orgs/imagegenius/packages/container/package/obico)

ImageGenius packages the Obico Server application into the container used by
this project. The ImageGenius repository is not the upstream Obico Server
application repository. The local Obico entrypoint relies on paths inside
that image, so image changes must be checked before updating.

## Coturn

- **Project and source:** [coturn/coturn](https://github.com/coturn/coturn)
- **Docker image:** [coturn/coturn on Docker Hub](https://hub.docker.com/r/coturn/coturn)

The official Coturn Docker image is used without modification. This
repository provides only an example configuration and Unraid template.

## Unraid

- **Unraid:** [Unraid](https://unraid.net/)
- **Community Applications:** [Community Applications plugin](https://github.com/CommunityApplications/Community-Applications)

The XML files in `templates/` are development exports. They are not claimed
to be official Unraid or Community Applications templates.

## Licensing

Obico Server and Moonraker-Obico identify their projects as licensed under
the GNU Affero General Public License version 3 (AGPL-3.0). The upstream
license text and component-specific attribution notes are provided in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and
[LICENSES/AGPL-3.0.txt](LICENSES/AGPL-3.0.txt).

No ZMOD source or firmware is bundled in this repository.
