# Changelog

## 1.1.6

- **Cihaz görünürlük filter (hassio integration skip):** HAOS addon'lar (NextForGen Agent, Tailscale, Mosquitto, File editor, Home Assistant Core, vs.) artık DB'ye gönderilmiyor. Filter HAOS'un `config_entries → domain = "hassio"` ayrımına dayanır, yanlış pozitif yok. HA WebSocket'e `config_entries/get` çağrısı eklendi; her cihazın `config_entries` field'ı kontrol edilir. Sonuç: backend'e sadece gerçek IoT cihazlar gider (Aqara, Sonoff, Yale, Matter cihazlar, RPi Power Status gibi fiziksel donanım dahil). Eklentiler DB'de **hiç görünmez**.

## 1.1.5

- Registry reload deadlock hotfix: 1.1.4'te eklenen dinamik discovery `LoadRegistryAsync`'i `Task.Run` ile paralel çağırıyordu — `ReceiveLoopAsync` ile aynı WS üzerinde concurrent `ReceiveAsync` olmaz, result mesajları event filter'ına takılıp kayboluyordu. Çözüm: reload sırasında WS `CloseAsync` ile kapatılıyor, outer reconnect döngüsü temiz yeniden bağlanıp `LoadRegistryAsync`'i tek-reader olarak çalıştırıyor.

## 1.1.4

- StateForwarder: HA `new_state: null` payload (entity silindiğinde) `InvalidOperationException` atıyordu — null-safe check eklendi (kritik crashloop fix)
- HA registry değişikliklerine (MQTT discovery, Z2M pair, vb.) dinamik tepki: `device_registry_updated` + `entity_registry_updated` event'lerine subscribe + 3sn debounce ile reload, artık agent restart gerekmiyor
- Backend reconnect race fix: ilk bağlantıda boş `device.list` array'i göndermiyor; registry hazır olunca cache'den dolu liste enqueue ediliyor (önceki davranışta backend tüm cihazları offline yapıyordu)
- HA WS receive loop: tek event handler exception'ı tüm bağlantıyı kırmıyor, log atıp devam ediyor

## 1.1.1

- run.sh CRLF hotfix (Windows host'ta Docker build sırasında CRLF dönüşümüne savunma)
- Cert path `/data/agent` → `/config` (HAOS addon update'lerinde `/data` volume sıfırlanabiliyor; `/config` (addon_config) persistent)
- HA registry race condition fix: subscribe result'ı tüket + sequential await

## 1.1.0

- Cert otomatik yenileme uygulandı: agent expire'a 30 gün kala backend'e `/api/hub/renew-cert` mTLS POST'u atar, atomik save sonrası reconnect tetikler
- Offline state buffer SQLite'a alındı (WAL mode): agent restart sonrası kritik sensör event'leri kayıp yaşamaz
- Reconnect backoff'a ±20% jitter eklendi: çoklu hub durumunda thundering herd koruması
- Backend tarafı (sadece referans için): `ConnectionRateLimiter` (429 ile reconnect storm koruması), `IHubBackplane` (Redis Pub/Sub ile scale-out hazırlığı, default NoOp), Devices/Rooms/Automations partial indexes, Location PreviousCert kolonları (renewal grace period)

## 1.0.0

- İlk sürüm
- mTLS ile Azure backend bağlantısı (outbound WebSocket)
- Zigbee (Z2M) + Matter cihaz kontrolü
- HA state event real-time forwarding
- LAN fallback HTTPS endpoint (port 9100, self-signed cert)
- mDNS service discovery (`_nextforgen-hub._tcp.local`)
- Bootstrap provisioning (tek kullanımlık kod)
- Cert otomatik yenileme (30 gün öncesi)
