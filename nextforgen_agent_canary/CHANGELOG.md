# Changelog — NextForGen Agent (Canary)

Canary kanali: yeni surumler once burada sahada dogrulanir, sonra stable `nextforgen_agent`'a
ayni surum numarasiyla terfi eder. Stable her zaman canary'den <= surumdedir.

## 1.1.37 (2026-07-29)

IntegrationHealthSupervisor (v2.1) agent ayagi — entegrasyon self-heal watchdog'u. Default KAPALI
(canary-first): enable YALNIZ bu canary manifestindeki `integration_watchdog_enabled` option'indan
gelir; stable `nextforgen_agent` manifestinde bu option YOKTUR -> jq default false -> stable'da ACILAMAZ.

- **feat(IntegrationHealthSupervisor):** Sinif-A (setup_error -> entegrasyon reload) self-heal, izinli
  domain'lerde (tuya, tapo); Sinif-B/B' (host onarimi, Tapo /24 UDP discovery ile IP kaymasi kurtarma)
  yalniz tapo. Reload oncesi vendor-readiness gate (DNS + TCP connect + TLS handshake, allowlist);
  backend-WS-reconnect tek basina gate ACMAZ, yalnizca "gate'i kontrol et" kenaridir.
- **feat(kalici durum):** Supervisor circuit + pending repair transaction'i SQLite'ta (/data) tutar;
  restart/update'te tekrar oynatilmaz (idempotent).
- **feat(canary-only option, S4c):** `integration_watchdog_entity_recovery_timeout_sec` (default 20,
  izinli 20..600) — repair sonrasi entity available bekleme penceresi. run.sh BOUNDED dogrular;
  eksik/gecersiz/aralik-disi -> 20'ye FAIL-CLOSED. Option yoksa urun davranisi (20sn SLO) degismez.

> Default kapali oldugundan sahaya inen image DAVRANIS DEGISTIRMEZ; watchdog yalniz canary test
> hub'inda `integration_watchdog_enabled: true` ile acilir (Berk ILK canary OLMAZ). Canary
> dogrulamasi (online + cihaz kontrol + self-heal gozlemi + offline-flap YOK) sonrasi degerlendirilir.

## 1.1.35 (2026-06-29)

P3-A (isim->HA propagasyonu) agent ayagi + G9 (gozlemlenebilirlik). Tamamen ADDITIVE;
baglanti/heartbeat/state-flush yollarina DOKUNMAZ (1.1.32 offline-flap sinifi DEGIL).
Berk hub'inda saha-dogrulamasi (tek hub, ayri canary buffer yok).

- **feat(P3-A device.rename):** Backend `device.rename` -> agent HA `config/device_registry/update` name_by_user.
- **feat(G9):** eslenmemis entity drop log (rate-limited, distinct entity basina tek).

## 1.1.34 (2026-06-25)

Gercek-zamanli senkron P1 turu — agent ayagi (C1 + C2). Backend state-concurrency (C3, ayri tur,
StateVersion compare-and-swap) ve mobil (C4/C5/C6) ayni calismada; bu add-on yalnizca agent image'ini tasir.

- **fix(C2 gap-resync):** Registry-reload reconnect'inde `get_states` ARTIK ATLANMAZ. 1.1.33'teki
  "skip" gap-resync'i bozuyordu: registry-reload HA WebSocket'i kapatir, kapali pencerede kacan HA
  durum degisiklikleri registry-only device.list (state tasimaz) ile kurtarilamiyor, bir daha emit
  etmeyen entity suresiz bayat kaliyordu. Ustelik skip zaten REST `/api/states` fallback'ine dusup
  HA Core yukunu KALDIRMIYORDU. Artik her reconnect `get_states` (WS, in-band) calistirir; bu snapshot
  `last_updated` tasir, backend §5 freshness her entity'yi (sessizce kacanlar dahil) uzlastirir, bayat
  baseline taze state'i geri sarmaz. HA Core yuku reconnect FREKANSI sorunuydu → 30sn debounce (1.1.33)
  zaten cozuyor; per-reconnect tek `get_states` ucuz.
- **feat(C1 last_updated propagation):** Agent HA `last_updated`'i device.list baseline'inda tasir
  (HaStateInfo → DeviceEntityRegistry.EntityInfo → backend). Boylece reconnect/resync baseline'i,
  disconnect penceresinde kacan gercek degisikligi taze timestamp'le getirince backend §5 freshness
  onu uygular (eskiden timestamp'siz baseline reddediliyordu = HA->app yansimasi bozuktu).

> Canary dogrulamasi (online + cihaz kontrol + reconnect resync + HA Core yuku normal) sonrasi bu
> surum stable `nextforgen_agent/config.yaml`'a 1.1.34 olarak terfi edilir.
