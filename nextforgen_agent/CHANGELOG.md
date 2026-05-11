# Changelog

## 1.1.0

- Cert otomatik yenileme uygulandı: agent expire'a 30 gün kala backend'e `/api/hub/renew-cert` mTLS POST'u atar, atomik save sonrası reconnect tetikler
- Offline state buffer SQLite'a alındı (WAL mode): agent restart sonrası kritik sensör event'leri kayıp yaşamaz
- Reconnect backoff'a ±20% jitter eklendi: çoklu hub durumunda thundering herd koruması
- Backend tarafı (sadece referans): `ConnectionRateLimiter` (429 ile reconnect storm koruması), `IHubBackplane` (Redis Pub/Sub scale-out hazırlığı, default NoOp), partial indexler, Location PreviousCert kolonları (renewal grace period)

## 1.0.0

- İlk sürüm
- mTLS ile Azure backend bağlantısı (outbound WebSocket)
- Zigbee (Z2M) + Matter cihaz kontrolü
- HA state event real-time forwarding
- LAN fallback HTTPS endpoint (port 9100, self-signed cert)
- mDNS service discovery (`_nextforgen-hub._tcp.local`)
- Bootstrap provisioning (tek kullanımlık kod)
- Cert otomatik yenileme (30 gün öncesi)
