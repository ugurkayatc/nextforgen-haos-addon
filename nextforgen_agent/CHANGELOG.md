# Changelog

## 1.1.5

- Registry reload deadlock hotfix: 1.1.4'te eklenen dinamik discovery `LoadRegistryAsync`'i `Task.Run` ile paralel Ã§aÄŸÄ±rÄ±yordu â€” `ReceiveLoopAsync` ile aynÄ± WS Ã¼zerinde concurrent `ReceiveAsync` olmaz, result mesajlarÄ± event filter'Ä±na takÄ±lÄ±p kayboluyordu. Ã‡Ã¶zÃ¼m: reload sÄ±rasÄ±nda WS `CloseAsync` ile kapatÄ±lÄ±yor, outer reconnect dÃ¶ngÃ¼sÃ¼ temiz yeniden baÄŸlanÄ±p `LoadRegistryAsync`'i tek-reader olarak Ã§alÄ±ÅŸtÄ±rÄ±yor.

## 1.1.4

- StateForwarder: HA `new_state: null` payload (entity silindiÄŸinde) `InvalidOperationException` atÄ±yordu â€” null-safe check eklendi (kritik crashloop fix)
- HA registry deÄŸiÅŸikliklerine (MQTT discovery, Z2M pair, vb.) dinamik tepki: `device_registry_updated` + `entity_registry_updated` event'lerine subscribe + 3sn debounce ile reload, artÄ±k agent restart gerekmiyor
- Backend reconnect race fix: ilk baÄŸlantÄ±da boÅŸ `device.list` array'i gÃ¶ndermiyor; registry hazÄ±r olunca cache'den dolu liste enqueue ediliyor (Ã¶nceki davranÄ±ÅŸta backend tÃ¼m cihazlarÄ± offline yapÄ±yordu)
- HA WS receive loop: tek event handler exception'Ä± tÃ¼m baÄŸlantÄ±yÄ± kÄ±rmÄ±yor, log atÄ±p devam ediyor

## 1.1.1

- run.sh CRLF hotfix (Windows host'ta Docker build sÄ±rasÄ±nda CRLF dÃ¶nÃ¼ÅŸÃ¼mÃ¼ne savunma)
- Cert path `/data/agent` â†’ `/config` (HAOS addon update'lerinde `/data` volume sÄ±fÄ±rlanabiliyor; `/config` (addon_config) persistent)
- HA registry race condition fix: subscribe result'Ä± tÃ¼ket + sequential await

## 1.1.0

- Cert otomatik yenileme uygulandÄ±: agent expire'a 30 gÃ¼n kala backend'e `/api/hub/renew-cert` mTLS POST'u atar, atomik save sonrasÄ± reconnect tetikler
- Offline state buffer SQLite'a alÄ±ndÄ± (WAL mode): agent restart sonrasÄ± kritik sensÃ¶r event'leri kayÄ±p yaÅŸamaz
- Reconnect backoff'a Â±20% jitter eklendi: Ã§oklu hub durumunda thundering herd korumasÄ±
- Backend tarafÄ± (sadece referans iÃ§in): `ConnectionRateLimiter` (429 ile reconnect storm korumasÄ±), `IHubBackplane` (Redis Pub/Sub ile scale-out hazÄ±rlÄ±ÄŸÄ±, default NoOp), Devices/Rooms/Automations partial indexes, Location PreviousCert kolonlarÄ± (renewal grace period)

## 1.0.0

- Ä°lk sÃ¼rÃ¼m
- mTLS ile Azure backend baÄŸlantÄ±sÄ± (outbound WebSocket)
- Zigbee (Z2M) + Matter cihaz kontrolÃ¼
- HA state event real-time forwarding
- LAN fallback HTTPS endpoint (port 9100, self-signed cert)
- mDNS service discovery (`_nextforgen-hub._tcp.local`)
- Bootstrap provisioning (tek kullanÄ±mlÄ±k kod)
- Cert otomatik yenileme (30 gÃ¼n Ã¶ncesi)
