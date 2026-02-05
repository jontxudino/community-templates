#!/bin/bash
# =============================================================================
# carbonio_mailstats.sh - Estadísticas de correo desde logs de Postfix
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_mailstats.sh
# =============================================================================

# Ruta del log de Postfix
MAIL_LOG="/var/log/mail.log"

# Alternativas de ubicación del log
if [ ! -f "$MAIL_LOG" ]; then
    MAIL_LOG="/var/log/carbonio/postfix.log"
fi
if [ ! -f "$MAIL_LOG" ]; then
    MAIL_LOG="/opt/zextras/log/mailbox.log"
fi

# Verificar que existe el log
if [ ! -f "$MAIL_LOG" ]; then
    echo 0
    exit 0
fi

# Fecha de hoy para filtrar últimas 24h
TODAY=$(date +%b\ %e)

case "$1" in
    bytes_sent)
        # Bytes enviados (sent)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep "sent" | grep -oP 'size=\K[0-9]+' | awk '{sum+=$1} END {print sum+0}'
        ;;
    bytes_received)
        # Bytes recibidos
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep "message-id=" | grep -oP 'size=\K[0-9]+' | awk '{sum+=$1} END {print sum+0}'
        ;;
    sent)
        # Mensajes enviados exitosamente
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "status=sent" || echo 0
        ;;
    received)
        # Mensajes recibidos
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "message-id=" || echo 0
        ;;
    rejected)
        # Mensajes rechazados
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "NOQUEUE: reject" || echo 0
        ;;
    bounced)
        # Mensajes rebotados
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "status=bounced" || echo 0
        ;;
    deferred)
        # Mensajes diferidos
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "status=deferred" || echo 0
        ;;
    *)
        echo "Uso: $0 {bytes_sent|bytes_received|sent|received|rejected|bounced|deferred}"
        exit 1
        ;;
esac
