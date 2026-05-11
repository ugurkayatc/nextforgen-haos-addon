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

### NextForGen Agent (Canary)

**Internal use only.** This add-on is the canary release channel and must only be installed on NextForGen test hubs.

- Slug: `nextforgen_agent_canary`
- Image: same `ghcr.io/ugurkayatc/agent`
- Currently installed on: **Berk hub** (canary test)

## Canary Release Workflow

NextForGen ships updates through a 2-stage rollout to avoid breaking customer hubs:

1. **Develop & build** — version bump in `NextForGen.Agent.csproj`, docker buildx + GHCR push of `ghcr.io/ugurkayatc/agent:X.Y.Z` and `:latest`.
2. **Canary** — bump `nextforgen_agent_canary/config.yaml` `version:` field, commit + push to `main`. Berk hub picks up the update within ~1 hour (HAOS Supervisor auto-update interval) provided that the canary add-on has auto-update enabled.
3. **Soak** — observe Berk hub for at least **24 hours**: no crash loops, backend log free of new errors, device flow intact.
4. **Promote to stable** — bump `nextforgen_agent/config.yaml` `version:` to the same version, commit + push. All production hubs auto-update within ~1 hour.

If the canary version misbehaves, **do not promote**. Fix and re-cycle through canary.

## Image

Both channels share the same multi-arch GHCR image. The slug separation provides install-side isolation; the channel choice happens at HAOS add-on store level by which add-on you install.

## Support

[nextforgen.com](https://nextforgen.com)
