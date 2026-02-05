#!/bin/bash
# =============================================================================
# carbonio_mailstats.sh - Estadísticas de correo desde logs de Postfix
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_mailstats.sh
# Compatible con Ubuntu 24.04 (formato de fecha ISO 8601)
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
if [ ! -f "$MAIL_LOG" ] || [ ! -r "$MAIL_LOG" ]; then
    echo 0
    exit 0
fi

# Fecha de hoy en formato ISO (YYYY-MM-DD) para Ubuntu 24.04
TODAY=$(date +"%Y-%m-%d")

# Función para asegurar que devolvemos un número válido
clean_number() {
    local val="$1"
    val=$(echo "$val" | tr -d '[:space:]')
    if [ -z "$val" ] || [ "$val" = "" ]; then
        echo 0
    else
        echo $((val + 0))
    fi
}

case "$1" in
    bytes_sent)
        # Bytes enviados (sent)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep "status=sent" | grep -oP 'size=\K[0-9]+' | awk '{sum+=$1} END {print sum+0}')
        clean_number "$result"
        ;;
    bytes_received)
        # Bytes recibidos
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep "message-id=" | grep -oP 'size=\K[0-9]+' | awk '{sum+=$1} END {print sum+0}')
        clean_number "$result"
        ;;
    sent)
        # Mensajes enviados exitosamente
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "status=sent")
        clean_number "$result"
        ;;
    received)
        # Mensajes recibidos (cleanup con message-id indica mensaje aceptado)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep "cleanup.*message-id=" | wc -l)
        clean_number "$result"
        ;;
    rejected)
        # Mensajes rechazados
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "NOQUEUE: reject")
        clean_number "$result"
        ;;
    bounced)
        # Mensajes rebotados
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "status=bounced")
        clean_number "$result"
        ;;
    deferred)
        # Mensajes diferidos
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "status=deferred")
        clean_number "$result"
        ;;
    *)
        echo "Uso: $0 {bytes_sent|bytes_received|sent|received|rejected|bounced|deferred}"
        exit 1
        ;;
esac
