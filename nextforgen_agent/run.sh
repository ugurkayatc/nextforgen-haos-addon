#!/usr/bin/env bashio

# HAOS addon config'inden options oku
BACKEND_URL=$(bashio::config 'backend_url')
PAIRING_CODE=$(bashio::config 'pairing_code')
PRE_SHARED_SECRET=$(bashio::config 'pre_shared_secret')
BOOTSTRAP_CODE=$(bashio::config 'bootstrap_code')
NFG_TAILSCALE_HELPER_SLUG=$(bashio::config 'nfg_tailscale_helper_slug')
LOG_LEVEL=$(bashio::config 'log_level')
# DevMode manifest schema'sından kaldırıldı (defense-in-depth) — bashio okumaz, export edilmez.
# Program.cs runtime guard prod backend + DevMode=true durumunu zaten zorla kapatır.

# Agent env değişkenlerine aktar (Bölüm 9.2 — Configuration form akışı)
# PSS değeri loglanmaz; PairingCode masked log alır.
export AGENT_Agent__BackendUrl="$BACKEND_URL"
export AGENT_Agent__PairingCode="$PAIRING_CODE"
export AGENT_Agent__PreSharedSecret="$PRE_SHARED_SECRET"
export AGENT_Agent__BootstrapCode="$BOOTSTRAP_CODE"
export AGENT_Agent__NfgTailscaleHelperSlug="$NFG_TAILSCALE_HELPER_SLUG"
export AGENT_Serilog__MinimumLevel__Default=$(echo "$LOG_LEVEL" | sed 's/\b\(.\)/\u\1/g')

# HA URL — HAOS supervisor üzerinden
export AGENT_Agent__HaUrl="http://supervisor/core"

# Cert + log klasörü — addon_config volume'a map edildi
export AGENT_Agent__CertPath="/config/cert.pfx"
export AGENT_Agent__KeyPath="/config/private.key"

bashio::log.info "NextForGen Agent başlatılıyor..."
bashio::log.info "Backend: $BACKEND_URL"
if [ -n "$PAIRING_CODE" ]; then
    bashio::log.info "Pairing code mevcut (FirstBootService backend'e tanıtım yapacak)"
fi
if [ -n "$BOOTSTRAP_CODE" ]; then
    bashio::log.info "Bootstrap code mevcut (legacy provisioning)"
fi

exec /app/NextForGen.Agent
