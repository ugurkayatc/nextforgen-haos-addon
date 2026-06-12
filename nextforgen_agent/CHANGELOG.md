# Changelog

## 1.1.30 (2026-06-13)

HA `/api/states` snapshot'ı `device.list` ile birlikte taşınır — mobile presentation overlay reconnect anında dolar.

- **feat(device.list-state-snapshot):** `BackendConnectionService.SendDeviceListAsync` HA REST üzerinden tüm entity state + attribute snapshot'ını çekip mesaja ekler. `DeviceEntityRegistry.GetAllDevices` her entity'nin canlı state + attribute'larını backend'e taşır.
- **resilience:** HA REST erişilemezse fallback registry-only (eski davranış); iyi veri `unknown` ile ezilmez. Hata `LogWarning` ile raporlanır.

**Saha etkisi:** Reconnect anında mobile light brightness slider, sensor LQI/RSSI ve friendly_name doğru gelir; ilk `state_changed` event'i beklemez. Backward-compat: eski backend yeni agent ile çalışır (snapshot field'ları ignored).

## 1.1.29 (2026-06-11)

1.1.28 pivot da yetmedi — Azure word-based exclusion saha testiyle kanıtlandı.

- **fix(health-endpoint-word-pivot):** Azure App Service'in `clientCertExclusionPaths` ayarı path family değil **word-based** — path'in herhangi bir yerinde `health` veya `heartbeat` kelimesi geçtiği sürece cert forward edilmiyor (saha kanıtı: `/api/agent/anything` → 404 ama `/api/agent/heartbeat` → 401). Canonical path `/api/agent/telemetry`'e taşındı. Eski 3 route (hub/health, hub/heartbeat, agent/heartbeat) geçiş için tutuluyor ama Azure'da hâlâ 401.

## 1.1.28 (2026-06-11)

1.1.27 fix pivot — Azure exclusion path family `/h` geniş çıktı, `/heartbeat` de takıldı.

- **fix(health-endpoint-pivot):** Canonical path artık `/api/agent/heartbeat` (önceki `/api/hub/heartbeat` Azure App Service `clientCertExclusionPaths` `/h` prefix family'sinde kalıp cert forward edilmeden 401 alıyordu — saha test sonucu doğruladı: `/heartbeat` de `/health` ile aynı kaderi paylaştı). `/api/agent/*` farklı path family olduğu için cert düzgün ulaşır. Backend `HubBootstrapController` 3 route dinler (agent/heartbeat canonical + hub/heartbeat + hub/health backward-compat ama Azure pratikte 401 döner).

## 1.1.27 (2026-06-11)

Hub health POST endpoint path fix — sahada keşfedilen sessiz prod bug.

- **fix(health-endpoint):** `HubHealthReporterService` artık `/api/hub/heartbeat` path'ine POST atıyor (eski `/api/hub/health` Azure App Service `clientCertExclusionPaths` prefix match'ine takılıp client cert'i forward edilmeden 401 alıyordu → TÜM hub'ların `HubHealthSnapshots` insert'leri sessizce başarısız oluyordu, Sağlık paneli her hub'da boş kalıyordu). Backend `HubBootstrapController` her iki path'i de dinler (dual route, 30 gün geçiş).
- **observability:** Hata `LogDebug` seviyesinde idi — production'da fark edilmemişti. Bu sürümde path düzeltildi; ileride benzer sessiz fail'lere karşı bir kez başarısız POST sonrası `LogWarning`'a yükseltmek backlog'da.

**Saha etkisi:** Sürüm sahaya indikten sonra Hub Detay > Sağlık paneli ilk 60-90 sn içinde dolar (CPU temp, throttle, RAM/disk, cert günleri, Tailscale status). `HubHealthAlarmService` background eşik tarama da gerçek verilerle çalışmaya başlar.

## 1.1.26 (2026-05-31)

P0 hardening (Codex review sonrası). Backend + Agent güvenlik/dayanıklılık düzeltmeleri.

- **security(dev-mode):** `dev_mode` HAOS manifest option+schema'sından kaldırıldı (kullanıcı artık Configuration UI'dan açamaz). `Program.cs` runtime guard eklendi: prod backend (`api.nextforgen.com`) + `DevMode=true` ise zorla `false` + critical log; local dev için `NFG_ALLOW_DEV_MODE=true` override gerekir. DevMode CA bypass (mTLS) + LAN auth bypass açtığı için defense-in-depth.
- **security(self-options-cleanup):** `ProvisioningPollService` self addon options cleanup artık `dev_mode`'u Supervisor'a geri POST etmiyor (`opts.Remove("dev_mode")`). Manifest'ten kaldırılan option'ın legacy `options.json` üzerinden dirilmesini ve schema-reject'ini önler. Root `nextforgen_agent/run.sh` artık `dev_mode` okumuyor/export etmiyor; image `run.sh` jq fallback (`.dev_mode // false`) legacy güvenlik için kalır.
- **fix(hub-offline-command):** `HubAgentDevicePlatformProvider` hub offline iken artık ölü `HubCommandQueue`'ya yazıp sessiz başarı dönmüyor — `HubOfflineException` fırlatır, controller/handler non-2xx döner. (Backend tarafı: legacy `/command` ve otomasyon action'ları offline'da artık "failed" raporlar; `/ha-command` zaten `ha_unavailable` dönüyordu.)

**Geriye uyumluluk:** Eski hub'larda `dev_mode` zaten `false` default'tu; davranış değişmez. Manifest versiyon bump'ı (1.1.25 → 1.1.26) HAOS Supervisor auto-update'i tetikler — sahadaki hub'lar bu güvenlik düzeltmesini alır.

## 1.1.25 (2026-05-29)

LAN P0 foundation (Codex review PASS — Berk hub smoke testi merge öncesi son şart). Detay: PR #28.

- **feat(lan-snapshot):** Backend `device.snapshot.push` mesaj kontratı eklendi. Backend mobile-uyumlu `DeviceDto[]` snapshot'ını periyodik ve mutation-tetiklemeli Agent'a push eder; Agent NFG Guid ↔ HA `device_id` mapping cache'ler. Mobile `/local/v1/devices` LAN modunda artık tam DeviceModel-compatible response döner.
- **feat(lan-ha-command):** `POST /local/v1/devices/{id}/ha-command` route eklendi. `HaLanCommandNormalizer` mobile cloud body shape'ini (`{command_id, target_entity, action, value:{...}}`) Agent `HaCommandTranslator`'ın beklediği flat shape'e çevirir — cloud `HaActionMapper` isim eşleştirmeleriyle birebir (`transition_seconds → transition`, `temperature_low/high → target_temp_low/high`). 8 E2E semantik testi geçiyor: select_option, set_brightness (+transition), set_temperature, set_temperature_range, set_position, lock+code, rgb_color array.
- **feat(lan-single-get):** `GET /local/v1/devices/{id}` tekil endpoint — mobile `getDeviceById` LAN modunda çalışsın diye. NFG Guid önce, HA device_id fallback.
- **feat(lan-state-ws):** `StateForwarder` HA state event'lerini backend WS'e yollarken artık `LocalEndpointService.BroadcastStateAsync`'i de çağırıyor — LAN subscriber'lar (mobile WS client gelince) anlık state event alır. Payload: `{deviceId: nfgGuid, entityId: realHaEntityId, newState, attributes}`. Mobile WS client implementasyonu MacBook'ta (`docs/lan_p0_mobil_plan.md`).
- **fix(lan-persistence) Codex P0 blocker:** `LanSnapshotStore` — backend'den gelen snapshot disk'e atomik yazılır (`/config/nextforgen-lan-snapshot.json`, tmp + `File.Move(overwrite)`). Hub restart / elektrik kesintisi sonrası backend bağlantısı kurulmadan önce LAN endpoint cached snapshot'ı serve eder. Corrupt JSON → warning + empty cache, Agent çökmez. Secret yok.
- **fix(lan-race) Codex P0 blocker:** `DeviceEntityRegistry.UpdateSnapshot` immutable replace pattern — eski Clear()+fill window'u içinde okuyucular boş cache görüp 404 alabiliyordu. Şimdi `Volatile.Write` ile atomic dictionary swap. Test (parallel 4 reader × 500 iter) empty observation = 0 garanti ediyor.
- **feat(lan-permissions):** `LanTokenClaims.Permissions` artık her endpoint'te enforce ediliyor — `device.read` GET/WS, `device.command` POST. Mevcut tokenlar her iki perm'i içerdiği için davranış bozulmaz; ileride read-only profil hazır.
- **doc:** `docs/lan_p0_mobil_plan.md` MacBook için sıkı plan — LAN WS client, getDeviceById LAN dispatch, test listesi, P0 kabul kriterleri. `docs/lan_p0_berk_smoke.md` saha runbook.

**Geriye uyumluluk garantileri:** Eski Agent (v1.1.24) `device.snapshot.push`'u "default" switch dalında ignore eder — saha breaking yok. Eski mobile NFG Guid `/ha-command` çağrısı yeni Agent NFG resolve + normalize → çalışır. Eski mobile `/command` HA device_id ile `ResolveTargets` fallback dalı → çalışır.

**Deploy Bağımlılığı:** Master image v1.0.5 build/upload/register, mobil sprint MacBook'ta uygulanıp Berk hub'da LAN acceptance PASS edilene kadar BEKLİYOR. **Bu sürüm prod'a deploy edilebilir** (eski mobile cloud modunda kalır; LAN modunda mobile WS subscribe etmediği için sadece komut yolu çalışır, state push sessizce gider).

## 1.1.24 (2026-05-24)

- **fix(lan-fallback):** Codex saha QA bulguları — LAN fallback production-ready hale getirildi. Mobil tarafı (MacBook) ile birlikte deploy edilmesi gerekir; bu sürüm Agent + Backend kontratı düzeltir, mobil değişiklik `docs/mobil_lan_fallback_fix.md` reçetesinde.
- **fix(mdns) Bulgu #1**: `LocalEndpointService` — `_mdns.Start()` artık gerçek `_locationId` ile yayın yapar (Subject'tan parse). `Guid.Empty` yayın bug'ı giderildi; mobil discovery bu güne kadar hep fail ediyordu.
- **fix(lifecycle) Bulgu P0-1**: Fresh master image'da cert YOK iken Agent başlarsa `_locationId = Guid.Empty` kalıyordu. `LocalEndpointService` artık background refresh loop ile her 15 saniyede `CertStore.HasValidCert()` kontrol eder; ProvisioningPollService cert yazar yazmaz `_locationId` gerçek değere güncellenir + mDNS restart edilir. Middleware token validation `GetLocationId()` lock'lu okuma ile güncel değeri kullanır.
- **fix(mdns-restart)**: `MDnsAdvertiser.Start()` artık idempotent + restart destekli. Aynı locationId ile tekrar çağrılırsa skip; farklı locationId ile yeniden yayın için eski instance Stop+Dispose, yeni instance Start. `Guid.Empty` çağrılırsa skip eder ve log warning yazar. `IsAdvertising` property eklendi.
- **fix(hello-cert) Bulgu P0-2**: `BackendConnectionService.TryGetLocalCertFingerprint()` artık LocalEndpointService'in EnsureLoaded yapmasını beklemez. Proaktif olarak `CertStore.HasValidCert()` → `ParseLocationId()` → `SelfSignedCertProvider.EnsureLoaded()` çağrı zinciri kurar. Race condition (hello fingerprint null gönderme riski) kapatıldı.
- **fix(backend-hello) Bulgu #2**: `HelloHandler.HelloPayload` record'a `LocalCertFingerprint` field eklendi. Handler artık format doğrulaması yapar — yalnızca `sha256:` + 64 lowercase hex pattern'ine UYAN fingerprint `Location.HubLocalCertFingerprint`'e yazılır. Geçersiz/null değer mevcut alanı override etmez.
- **fix(lan-token) Bulgu P0-3**: `GetLanTokenQuery` artık boş/invalid fingerprint ile token üretmez. Format `sha256:[0-9a-f]{64}` regex doğrulaması ile kontrol edilir; başarısız ise HTTP **425 Too Early** döner ("LAN fingerprint henüz hazır değil; hub Agent'tan hello bekleniyor"). Eski davranış (boş secret ile token imzalama) tamamen kapatıldı.
- **doc**: `docs/mobil_lan_fallback_fix.md` MacBook ekibine reçete — `.gitignore` exception eklendi, Codex koordinasyonu için artık GitHub'da. Credential YOK.

**Deploy Bağımlılığı**: Master image v1.0.4 build/upload/register, mobil fix MacBook'ta uygulanıp Berk hub'da LAN acceptance PASS edilene kadar BEKLİYOR. Bu sürüm prod'a deploy edilebilir (mobil değişmeden de tek başına çalışır — sadece null-fingerprint guard'ları sayesinde mobil eski sürüm de cloud modunda kalır).

## 1.1.23 (2026-05-24)

- **feat(remote-update):** `system.update_addons` capability + handler eklendi. Backend release sonrası tüm hub'lara push notification ile add-on update tetiklenebilir — HAOS auto_update 0-24 saat gecikmesini bypass eder.
- `SupervisorClient`: `ReloadStoreAsync()` (POST /store/reload), `UpdateAddonAsync(slug)` (POST /addons/{slug}/update), `GetAddonInfoAsync(slug)` (version + state snapshot, before/after diff için) eklendi.
- `BackendConnectionService.HandleUpdateAddonsAsync` — payload `{ slugs?, reloadStore? }`. Allowlist: yalnızca `NfgTailscaleHelperSlug` ve `self`. Arbitrary slug **reddedilir**. Default sadece helper (self-update `[\"self\"]` ile explicit). Sonuç `system.update_addons_result` `{ success, results: [{slug, beforeVersion, afterVersion, state, updated, message}], durationMs }`.
- Idempotent: Supervisor "already up-to-date" 400 hatasını skip olarak işler, fail değil.
- Self-update sırasında Supervisor agent container'ını restart ettiği için WS kopabilir; backend timeout 120s — teknisyen 504 görürse hub status'unu birkaç dakika sonra kontrol etmelidir.

## 1.1.22 (2026-05-23)

- **fix(reapply):** `HandleReapplyTailscaleAsync` helper options payload'una `log_level = "info"` eklendi. HAOS Supervisor `POST /addons/{slug}/options` PARTIAL update desteklemediği için helper schema'daki tüm mandatory alanlar dolu gönderilmek zorunda. log_level eksikliği nedeniyle Supervisor 400 dönüyordu (sahada Berk hub'da T4 acceptance test failure). Sansürleme çalıştı: 400 error body'sinde "authkey" geçtiği için log `[REDACTED:contains authkey-like substring]` ile maskelendi.

## 1.1.21 (2026-05-23)

- **feat(tailscale):** Uzaktan watchdog + restart + re-apply zinciri (müşteri evinden fiziksel müdahale gerekmeyecek şekilde).
- `system.hello.capabilities` artık `system.restart_tailscale` + `system.reapply_tailscale` ilan eder.
- `BackendConnectionService.HandleRestartTailscaleAsync` — backend `system.restart_tailscale` mesajını işler; Supervisor `SetAddonOptionsAsync`/`RestartAddonAsync`/`GetAddonStateAsync` kombinasyonu ile addon restart eder, 3×10s "started" poll, `system.restart_tailscale_result` döner.
- `BackendConnectionService.HandleReapplyTailscaleAsync` — backend canonical payload (authkey, hostname, advertise_tags, accept_dns, accept_routes) ile helper options'ı yeniden yazıp restart eder. Slug payload'dan ALINMAZ (yalnızca `_options.NfgTailscaleHelperSlug`). Authkey **hiçbir log/response/audit çıktısına yazılmaz**.
- `SupervisorClient.SetAddonOptionsAsync` error body'sinde `RedactSensitive` — `tskey-` / `authkey` / `auth_key` pattern'i bulunursa `[REDACTED]`.
- `HubHealthReporterService` — Tailscale durumu yalnızca helper addon Supervisor state'i (`started`/`stopped`/`error`/`not_installed`/`auth_failed`/`unknown`). userspace-networking modunda tailscale0 interface yok, `TailscaleIp`/`TailscaleHost` daima null.
- `auth_failed` raporu: `/share/.nfg-auth-failed` marker varsa Supervisor state'in üstüne yazılır. Self-heal `auth_failed` durumunda devre dışı (restart yetmez sinyali — backend re-apply göndermek zorundadır).
- Self-heal exponential backoff `[60, 120, 300, 600, 1800]` saniye + circuit breaker (5 deneme sonrası açık).
- Hardcoded `a0d7b954_tailscale` referansı kaldırıldı; her yerde `AgentOptions.NfgTailscaleHelperSlug` kullanılır.

## 1.1.19 (2026-05-18)

- **breaking(provisioning):** HA admin password reset akışı kaldırıldı. Backend `FinalizeHubResult.HaAdminPassword` artık dönmüyor, Agent B3 `ResetAuthPasswordAsync` çağırmıyor.
- Rationale: Tailscale-only erişim modelinde teknisyen/müşteri HA UI'a master image'daki bilinen `nfg_admin` şifresiyle giriyor. Single-shot random parola ops sürekliliğini bozuyordu (her hub'da farklı, müşteriye verilmeyen, teknisyen bile bilmeyen şifre).
- State machine sadeleştirildi: B2a/B2b → tek B2 + B2-recovery (cert var ama `tailscale_authkey` yok).
- `NfgState.HaAdminPassword` + `HaAdminReset` field'ları kaldırıldı (System.Text.Json bilinmeyen JSON field'ları sessizce yok sayar, eski state.json dosyaları geriye dönük çalışır).
- `CanWriteFinalMarker` koşulu: artık sadece phase1 + hostname + tailscale + cert + ack + selfClean.
- `SupervisorClient.ResetAuthPasswordAsync` + `DeleteAuthCacheAsync` mevcut kalır (çağrılmıyor, ileride gerekirse hazır).
- v1.0.3 master image build için PASS şartı.

## 1.1.18 (2026-05-18)

- fix(run.sh): nfg_tailscale_helper_slug option okuma + AGENT_Agent__NfgTailscaleHelperSlug export. v1.1.17 ve öncesinde docker image run.sh bu field'i okumadığı için AgentOptions.NfgTailscaleHelperSlug runtime'da daima default değer kullanılıyordu — kullanıcı override (HAOS Configuration form'unda farklı slug) etkisiz idi. Default (f43b29bd_nfg_tailscale_helper) tesadüfen doğru olduğu için Berk hub'ta sorun çıkmadı, ama prensip olarak bug.

## 1.1.17 (2026-05-18)

- fix(self-options-cleanup): /data/options.json'dan mevcut TÜM options okunur, sadece pairing_code + pre_shared_secret boşaltılır, HAOS'a full options object gönderilir. v1.1.16'da partial update HAOS validation (Missing option 'bootstrap_code') hatası verip B3 marker'ı bloke ediyordu — Track C saha testinde state.json manuel hack ile aşıldı. Bu sürümde otomatik akış.
- log_level + nfg_tailscale_helper_slug + dev_mode kullanıcı override değerleri **korunur** (hardcoded 'info' DEĞİL — kullanıcı seçimi).

## 1.1.16 (2026-05-18)

- hassio_role: admin — /host/options + /auth/reset endpoint'leri için zorunlu (Bölüm 9.7 finalize akışı default rolde 403)
- GHCR image binary değişmedi (1.1.15 ile aynı) — sadece manifest permission patch

## 1.1.15 (2026-05-17)

- BÃ¶lÃ¼m 9.2 canonical: claim-status / finalize / finalize-ack akÄ±ÅŸÄ± (`ProvisioningPollService`)
- B1/B2a/B2b state machine + atomic `/config/.nfg-state.json` (temp + rename POSIX)
- Plan K: `NfgTailscaleHelperApplier` â€” Tailscale apply finalize fazÄ±nda, `nfg_tailscale_helper` addon ile (community `a0d7b954_tailscale` artÄ±k kullanÄ±lmÄ±yor)
- `SupervisorClient.ResetAuthPasswordAsync` + `DeleteAuthCacheAsync` + `SetSelfAddonOptionsAsync` + `RestartAddonAsync` + `GetAddonStateAsync`
- `FirstBootService` revize (P1-4): phase1_done set ise first-boot Ã§aÄŸrÄ±sÄ± atlar; marker artÄ±k ProvisioningPollService B3'te yazÄ±lÄ±r
- `BackendConnectionService` state-aware gate (P1-3): marker + cert + pairing + bootstrap_code kombinasyonuna gÃ¶re 5 branch
- `BootstrapService` legacy guard: pairing dosyasÄ± varsa no-op (yeni akÄ±ÅŸ ile Ã§akÄ±ÅŸmasÄ±n)
- `auth_api: true` (Supervisor `/auth/*` endpoint'lerine eriÅŸim iÃ§in zorunlu)
- Marker Ã¶nkoÅŸulu sert: tÃ¼m flag'ler true + ha_admin_password set olmadan `/config/.nfg-firstboot-done` yazÄ±lmaz
- **Configuration form akÄ±ÅŸÄ± (BÃ¶lÃ¼m 9.2 fix-only Bulgu 1):** addon Configuration sekmesinde `pairing_code` + `pre_shared_secret` alanlarÄ± (password masked) â€” teknisyen yapÄ±ÅŸtÄ±rÄ±r. `PairingResolver` form/JSON source priority (AgentOptions Ã¶nce, sonra `/config/.nfg-pairing.json`, sonra boot partition)
- **Secret cleanup (Bulgu 2):** final marker sonrasÄ± `/config/.nfg-pairing.json` silinir; `SetSelfAddonOptionsAsync` pairing_code + pre_shared_secret temizler
- **hubProvisioningId fallback (Bulgu 3):** Backend claim-status / finalize / finalize-ack endpoint'leri PairingCode VEYA HubProvisioningId fallback (FirstBootHub pattern). Agent legacy JSON akÄ±ÅŸÄ±nda GUID string'i PairingCode field'Ä±na KOYULMAZ; HubProvisioningId field'Ä±nda gÃ¶nderilir.
- **NFG Helper slug (Bulgu 4):** `AgentOptions.NfgTailscaleHelperSlug` (default `f43b29bd_nfg_tailscale_helper`). HAOS install slug repo prefix ile deÄŸiÅŸebilir, runtime config ile yÃ¶netilir.
- **Tailscale apply gÃ¼venilirliÄŸi (Bulgu 5):** Helper restart sonrasÄ± 30s wait Ã— 3 deneme + state "error" gÃ¶rÃ¼rse restart retry (sadece "started" baÅŸarÄ± kabul edilir)
- **FinalizeAck gÃ¼venliÄŸi (Bulgu 6):** `success=false` ile gelen ACK PSS revoke YAPMAZ â€” hub Assigned'da kalÄ±r, Agent retry yapabilir

## 1.1.14

- **Saha UX revisi:** JSON dosya yaklaşımı bırakıldı. Pairing artık HAOS addon Configuration form'undan yapılır
- `config.yaml`: yeni opsiyon `pairing_code` (str?) ve `pre_shared_secret` (password?) eklendi
- `run.sh`: options.json'dan iki yeni alanı okur, `AGENT_Agent__PairingCode` + `AGENT_Agent__PreSharedSecret` env'ine export eder
- `AgentOptions`: `PairingCode` + `PreSharedSecret` property'leri
- `FirstBootService` refactor: pairing kaynağı önceliği = (1) addon options → (2) `/config/.nfg-pairing.json` → (3) `/boot/` adayları. Geriye dönük uyumlu, idempotent
- Backend `/api/hub/first-boot`: `PairingCode` field destekli (8 hex), `HubProvisioningId` artık opsiyonel. PairingCode öncelikli kontrol edilir
- Teknisyen saha akışı: panel'den pairing code+secret kopyala → HA UI → Settings → Add-ons → NextForGen Agent → Configuration sekmesine yapıştır → Save. Boot partition mount / JSON dosya gerekmez

## 1.1.13

- FirstBootService boot partition'Ä± da arar: `/mnt/boot/.nfg-pairing.json`, `/boot/.nfg-pairing.json`, `/mnt/data/.nfg-pairing.json`
- Boot partition'da bulunan pairing JSON'Ä± `/config/.nfg-pairing.json`'a otomatik taÅŸÄ±r, sonra normal akÄ±ÅŸ devam eder
- Teknisyen RPi Imager + JSON sÃ¼rÃ¼kle-bÄ±rak yapabilir â€” manuel LLT artÄ±k gerekli deÄŸil

## 1.1.12

- A6: `pair_mode.enable` mesajÄ± eklendi (BackendConnectionService)
- Z2M MQTT `zigbee2mqtt/bridge/request/permit_join` publish (HA REST `/api/services/mqtt/publish`)
- VarsayÄ±lan 60sn pencere; backend command'dan `durationSeconds` parametresi alÄ±r

## 1.1.11

- A5b: SupervisorClient (HAOS REST API, SUPERVISOR_TOKEN auth)
- FirstBootService geniÅŸletildi: Tailscale addon options + start + hostname swap
- Tailscale community addon `authkey` field destekliyorsa otomatik tailnet join

## 1.1.10

- Yeni `FirstBootService` (Provisioning) â€” fabrika-flaÅŸlanmÄ±ÅŸ hub aÃ§Ä±lÄ±ÅŸÄ±nda bir kez Ã§alÄ±ÅŸÄ±r
- `/config/.nfg-pairing.json` okur, backend `/api/hub/first-boot`'a kendisini tanÄ±tÄ±r
- Ä°dempotent (`/config/.nfg-firstboot-done` markeri)
- Geriye dÃ¶nÃ¼k uyumlu: pairing dosyasÄ± yok ise skip eder, mevcut bootstrap akÄ±ÅŸÄ± deÄŸiÅŸmeden Ã§alÄ±ÅŸÄ±r
- 100+ mÃ¼ÅŸteri Ã¶lÃ§ek mimarisi A3 â€” Tailscale auth ve hostname swap A5'te eklenecek

## 1.1.9

- Tailscale operasyonel durumu artÄ±k health raporuna eklenir (Supervisor `/network/info` ile IP, `/addons/{slug}/info` ile state)
- Backend `Location.TailscaleIp`/`TailscaleStatus` alanlarÄ±na 60sn'de bir snapshot yazar â€” operasyon paneli uzaktan eriÅŸim durumu iÃ§in bunu okur
- Backward compatible: eski backend yeni alanlarÄ± null tolere eder; bu Agent eski backend'le konuÅŸursa fazladan alanlar gÃ¶rmezden gelinir

## 1.1.8

- CI/CD pipeline doÄŸrulama sÃ¼rÃ¼mÃ¼ (Docker image build + GHCR push)
- Hub provisioning iyileÅŸtirmeleri (WebSocket Supervisor API, idempotent install, core_ssh, SCP branding upload)

## 1.1.7

- HAOS auto-update CI/CD pipeline iyileÅŸtirmesi
- `agent-deploy.yml`: GHCR image tag dÃ¼zeltmesi (`ugurkayatc/agent`)

## 1.1.6

- HAOS hassio integration filter â€” addon container DB cihazlarÄ± artÄ±k kullanÄ±cÄ± listesine sÄ±zmÄ±yor

## 1.1.5

- HA registry reload deadlock fix
- Null-safe state event handling
- Dynamic discovery + hub message receive logging

## 1.1.3

- HA registry load race condition fix (subscribe result tÃ¼ket + sequential await)

## 1.1.2

- Cert ve key path `/data/agent` â†’ `/config` taÅŸÄ±ndÄ± (HAOS persistent storage)

## 1.1.1

- `run.sh` CRLF hotfix (Windows satÄ±r sonu Linux container'da bozuyordu)

## 1.1.0

- Sertifika otomatik yenileme (30 gÃ¼n Ã¶ncesi)
- Offline event buffer (SQLite, kritik state'ler iÃ§in)
- Reconnect jitter + rate limit
- Redis backplane (scale-out hazÄ±rlÄ±k)

## 1.0.0

- Ä°lk sÃ¼rÃ¼m
- mTLS ile Azure backend baÄŸlantÄ±sÄ± (outbound WebSocket)
- Zigbee (Z2M) + Matter cihaz kontrolÃ¼
- HA state event real-time forwarding
- LAN fallback HTTPS endpoint (port 9100, self-signed cert)
- mDNS service discovery (`_nextforgen-hub._tcp.local`)
- Bootstrap provisioning (tek kullanÄ±mlÄ±k kod)
