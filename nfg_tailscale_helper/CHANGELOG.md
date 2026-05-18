# Changelog

## 1.0.1 (2026-05-18)

- Critical fix: Dockerfile TARGETARCH (aarch64 image had amd64 binary)

## 1.0.0 (2026-05-18)

- Initial release (Plan K, POC PASS sonrasÄ± canonical production sÃ¼rÃ¼mÃ¼)
- NFG hub'larÄ±nda `tag:nfg-provisioning` etiketli otomatik Tailscale join
- Schema `authkey: password?` field destekler (community Tailscale addon'unda yok)
- Tailscale 1.98.2 binary + SHA256 pin
- arch: aarch64 (RPi 5) + amd64
