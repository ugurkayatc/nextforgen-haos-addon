# Changelog

## 1.1.3

- **KRİTİK cihaz akış bug**: HaWebSocketClient.ConnectAsync `subscribe_events` result'ını tüketmiyordu (`_ = ReceiveMessageAsync`) + `LoadRegistryAsync` Task.Run ile fire-and-forget. Sonuç: registry response'ları kaybediliyordu, OnRegistryLoaded tetiklenmiyordu, backend'e device.list mesajı hiç gitmiyordu. Düzeltme: subscribe result `await`, registry sequential `await`. İlk başlatmada `HA registry yüklendi: N device, M entity` INFO logı görünür.

## 1.1.2

- **KRİTİK altyapı düzeltmesi**: Cert path `/data/agent/cert.pfx` → `/config/cert.pfx`. HAOS addon konvansiyonu (`addon_config:rw` map'i ile persistent). Önceki sürümlerde addon restart sonrası cert kayboluyor, agent her seferinde yeniden bootstrap istiyordu (bootstrap kodu zaten kullanıldı 401). Artık restart'ta cert korunur.
- StateBuffer SQLite `/config/state_buffer.db`'e otomatik taşınır (CertificateStore klasör tabanlı).

## 1.1.1

- 1.1.0 imajında run.sh CRLF nedeniyle başlatılamıyordu. Dockerfile'a `sed -i 's/\r$//'` savunma + .gitattributes ile `*.sh eol=lf`.

## 1.1.0

- Cert otomatik yenileme: agent expire'a 30 gün kala backend'e `/api/hub/renew-cert` mTLS POST'u atar, atomik save sonrası reconnect.
- Offline state buffer SQLite (WAL mode): agent restart sonrası kritik sensör event'leri kayıp yaşamaz.
- Reconnect backoff'a ±20% jitter (thundering herd koruması).
- Backend tarafı: `ConnectionRateLimiter`, `IHubBackplane` (Redis Pub/Sub scale-out hazırlığı, default NoOp), partial indexler, Location PreviousCert kolonları.

## 1.0.0
- İlk sürüm
- mTLS ile Azure backend bağlantısı (outbound WebSocket)
- Zigbee (Z2M) + Matter cihaz kontrolü
- HA state event real-time forwarding
- LAN fallback HTTPS endpoint (port 9100, self-signed cert)
- mDNS service discovery (`_nextforgen-hub._tcp.local`)
- Bootstrap provisioning (tek kullanımlık kod)
