# Changelog — NextForGen Agent (Canary)

Canary kanali: yeni surumler once burada sahada dogrulanir, sonra stable `nextforgen_agent`'a
ayni surum numarasiyla terfi eder. Stable her zaman canary'den <= surumdedir.

## 1.1.38 (2026-08-03)

1.1.37 watchdog handshake'inin saglamlastirilmasi. DIKKAT: bu surum `integration_watchdog_enabled: false`
(varsayilan) yolunun TEL uzerindeki davranisini DA degistirir. Yayinli 1.1.37, watchdog'a ozgu
`config_entries/subscribe` frame'ini option kapali olsa bile HER HA connect'inde gonderiyordu; 1.1.38 bu
frame'i option'in arkasina alir, dolayisiyla kapali yolda hic watchdog-abonelik trafigi CIKMAZ.
Cihaz/ozellik davranisi (reload/repair aksiyonlari) kapaliyken yine YAPILMAZ — degisen tek sey, bosuna
gonderilen bu abonelik frame'inin kaldirilmasidir.

- **fix(config_entries/subscribe gate):** Watchdog abonelik handshake'i artik YALNIZ
  `IntegrationWatchdog.Enabled` iken gonderilir. Kapali -> `_configEntrySubId` `-1` kalir; receive loop'taki
  `> 0` guard'lari config-entry yolunu inert tutar. (Yayinli 1.1.37'de bu gate YOKTU; frame her connect'te
  gidiyordu — 1.1.38'in kapali-yol tel degisikligi budur.)
- **fix(config_entries/subscribe reconnect):** Abonelik yaniti bounded-timeout'a duser VEYA WS kapanirsa
  (soket olu), ConnectAsync artik sessizce "basarili" donmez. Onceki davranis backoff'u sifirlayip
  gecikmesiz reconnect hot-loop'una (HA Core flap riski) yol aciyordu; artik `InvalidOperationException`
  atilip mevcut dis reconnect/backoff yoluna (exponential + jitter) giriliyor.
- **fix(nullable success fail-closed):** `HaWsResultMessage.Success` nullable (bool?); abonelik YALNIZ
  acik `success == true` iken aktif sayilir. `success:false`, `success:null` veya eksik alan -> soket ACIK
  kaldigindan fail-soft: sanitize warning + abonelik pasif, registry AYNI baglantida tam yuklenir. (Bu, olu
  soket -> reconnect yolundan AYRIDIR: acik-soket reddi = fail-soft; timeout/kapali-soket = reconnect.)
- **chore(deploy guard, ana repo):** Agent workflow'u push ONCESI mevcut surum tag'ini registry'de dogrular;
  YALNIZ dogrulanmis tag-not-found push'a izin verir, tag VARSA veya auth/network/timeout/5xx belirsizliginde
  FAIL-CLOSED durur (yayinli digest'i ezme korumasi). Es-zamanli publish run'lari tek `concurrency` grubunda
  siraya sokulur (calisan publish iptal EDILMEZ).

> KAPALI yol artik tel uzerinde de sessizdir: watchdog aksiyonlari kapaliyken calismaz VE watchdog-abonelik
> frame'i gonderilmez. Bu surum yayinli 1.1.37 canary'nin yerine gecer; 1.1.37 tag'i/digest'i DEGISMEDEN
> kalir. Yayinlanan digest'ler (dogrulandi 2026-08-03):
>
> - `:1.1.38` = `:latest` index `sha256:7c62b4a65456590c4b5f65f0a4c78d7fc8c71606297b5cf4233ac61f44af463c`
>   (linux/arm64 child `sha256:efa1d73dcff06a1beb5b2fe7ff1303cd1bc31afcfef797f920181f92665edc5d`)
> - `:1.1.37` index `sha256:b280a46174d7e98ca31f7b0cf89265d2aac9939e689bd1180ce2df00f135eafb` (DEGISMEDI)
>
> Canary dogrulamasi (Berk ILK canary OLMAZ) sonrasi stable terfi AYRI adimdir.

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
>
> _(Duzeltme 2026-08-03, 1.1.38 ile): Yukaridaki "DAVRANIS DEGISTIRMEZ" cihaz/urun davranisi (self-heal
> aksiyonlari) icin dogrudur, ama TEL uzerinde tam degildi — 1.1.37 watchdog kapaliyken de HER connect'te
> watchdog'a ozgu `config_entries/subscribe` frame'ini gonderiyordu. 1.1.38 bu frame'i gate'ler (kapali
> yolda hic gonderilmez); ayrinti icin 1.1.38 girdisine bakiniz. 1.1.37 tag/digest degismez._

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
