# NextForGen HAOS Add-on Repository

Official Home Assistant OS add-on repository for the NextForGen Smart Home Platform.

## Adding the Repository

In HAOS Supervisor: **Settings → Add-ons → Add-on Store → menu → Repositories**, paste:

    https://github.com/ugurkayatc/nextforgen-haos-addon

## Available Add-ons

### NextForGen Agent (stable)

Production-ready add-on installed on customer hubs.

- Slug: `nextforgen_agent`
- Image: `ghcr.io/ugurkayatc/agent` (linux/arm64)
- Install on every customer hub. Enter the bootstrap code from technician panel and start.

## Release Workflow

NextForGen ships updates through a single **stable** channel. "Test before customers" happens on a dedicated stable **test hub** that is updated ahead of customer hubs:

1. **Develop & build** — bump `<Version>` in `NextForGen.Agent.csproj`, push to `main`. GitHub Actions (`agent-deploy.yml`) source-release build pushes `ghcr.io/ugurkayatc/agent:X.Y.Z` + `:latest` to GHCR (gated: csproj must equal the stable manifest version, CHANGELOG entry present, no-clobber).
2. **Publish the manifest** — bump `nextforgen_agent/config.yaml` `version:` (+ a `CHANGELOG.md` entry) to the same version. This is a metadata-only change: CI only verifies the `:X.Y.Z` tag already exists in GHCR and pushes nothing.
3. **Test hub first** — on the dedicated stable test hub (a non-customer hub), update the Agent add-on manually ("Güncelle"), or temporarily enable auto-update on that hub only. Soak for at least **24 hours**: no crash loops, backend log clean, device flow intact.
4. **Roll out to customers** — customer hubs keep Agent `auto_update: false`, so they never auto-ship an untested build. After the test hub soaks clean, update each customer hub manually.

If the version misbehaves on the test hub, **do not roll out**. Fix and re-cycle.

### Auto-update behavior

The NextForGen provision script (`scripts/hub-provision/New-NfgHub.ps1`) sets auto-update **per add-on**:

- **NextForGen Agent → `auto_update: false`** (forced on both fresh install and restore). A stable bump must never auto-ship to a customer hub before it is tested — the operator updates the Agent manually after the test hub soaks clean.
- **Tailscale, Mosquitto, Z2M, Advanced SSH → `auto_update: true`** (unchanged).

To update the Agent on a specific hub:

- HA UI → Settings → Add-ons → NextForGen Agent → **Update** (or toggle "Auto update" on the test hub only)
- Or REST: `curl -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons/nextforgen_agent/update`

## Image

The Agent add-on pulls the multi-arch GHCR image `ghcr.io/ugurkayatc/agent`. The manifest `version:` pins which published image tag a hub installs.

## Support

[nextforgen.com](https://nextforgen.com)
