# Changelog — NextForGen Agent (Canary)

Canary kanali: yeni surumler once burada sahada dogrulanir, sonra stable `nextforgen_agent`'a
ayni surum numarasiyla terfi eder. Stable her zaman canary'den <= surumdedir.

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
