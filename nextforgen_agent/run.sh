#!/usr/bin/env bashio

# HAOS addon config'inden options oku
BACKEND_URL=$(bashio::config 'backend_url')
BOOTSTRAP_CODE=$(bashio::config 'bootstrap_code')
LOG_LEVEL=$(bashio::config 'log_level')
DEV_MODE=$(bashio::config 'dev_mode')

# Agent env değişkenlerine aktar
export AGENT_Agent__BackendUrl="$BACKEND_URL"
export AGENT_Agent__BootstrapCode="$BOOTSTRAP_CODE"
export AGENT_Agent__DevMode="$DEV_MODE"
export AGENT_Serilog__MinimumLevel__Default=$(echo "$LOG_LEVEL" | sed 's/\b\(.\)/\u\1/g')

# HA URL — HAOS supervisor üzerinden
export AGENT_Agent__HaUrl="http://supervisor/core"

# Cert + log klasörü — addon_config volume'a map edildi
export AGENT_Agent__CertPath="/config/cert.pfx"
export AGENT_Agent__KeyPath="/config/private.key"

bashio::log.info "NextForGen Agent başlatılıyor..."
bashio::log.info "Backend: $BACKEND_URL"

exec /app/NextForGen.Agent
