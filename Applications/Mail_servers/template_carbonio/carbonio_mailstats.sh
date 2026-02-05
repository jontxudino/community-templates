#!/bin/bash
# =============================================================================
# carbonio_mailstats.sh - Estadísticas de correo desde logs de Postfix
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_mailstats.sh
# Compatible con Ubuntu 24.04 (formato de fecha ISO 8601)
# Versión: 1.2 (con caché y correlación)
# =============================================================================

# Configuración
CACHE_DIR="/tmp"
CACHE_TTL=600  # 10 minutos
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
    # Si ejecutamos interactivamente, mostrar error
    if [ -t 1 ]; then
        echo "Error: Cannot read $MAIL_LOG. Check permissions." >&2
    fi
    echo 0
    exit 0
fi

# Fecha de hoy en múltiples formatos (regex robusta)
TODAY_ISO=$(date +"%Y-%m-%d")
MONTH=$(date +"%b")
DAY=$(date +"%e" | tr -d ' ')
# Regex matches "Feb 5" and "Feb  5" using POSIX character class for compatibility
TODAY_SYSLOG="$MONTH[[:space:]]+$DAY"
LOG_DATE="($TODAY_ISO|$TODAY_SYSLOG)"

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

# Funciones de cálculo
calc_bytes_sent() {
    # Bytes enviados (correlación: qmgr tiene tamaño, smtp tiene status=sent)
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep -E "postfix/qmgr|postfix/smtp" | awk '
    {
        # Buscar ID de cola (hexadecimal mayúscula seguido de :)
        if (match($0, /[0-9A-F]+:/)) {
            id = substr($0, RSTART, RLENGTH-1)
            
            # Si es qmgr y tiene size, guardar
            if ($0 ~ /postfix\/qmgr/ && match($0, /size=[0-9]+/)) {
                size = substr($0, RSTART+5, RLENGTH-5)
                sizes[id] = size
            }
            # Si es smtp y status=sent, sumar
            else if ($0 ~ /postfix\/smtp/ && $0 ~ /status=sent/) {
                if (id in sizes) {
                    sum += sizes[id]
                }
            }
        }
    }
    END { print sum+0 }
    '
}

calc_bytes_received() {
    # Bytes recibidos (usamos qmgr que registra el tamaño de todos los mensajes activos)
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep "postfix/qmgr" | grep "size=" | grep -oP 'size=\K[0-9]+' | awk '{sum+=$1} END {print sum+0}'
}

calc_sent() {
    # Mensajes enviados exitosamente
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep -c "status=sent"
}

calc_received() {
    # Mensajes recibidos (cleanup con message-id indica mensaje aceptado)
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep "cleanup.*message-id=" | wc -l
}

calc_rejected() {
    # Mensajes rechazados
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep -c "NOQUEUE: reject"
}

calc_bounced() {
    # Mensajes rebotados
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep -c "status=bounced"
}

calc_deferred() {
    # Mensajes diferidos
    grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | grep -c "status=deferred"
}

# Función para actualizar caché
update_cache() {
    local metric=$1
    local func=$2
    local cache_file="${CACHE_DIR}/zabbix_carbonio_mailstats_${metric}.cache"
    local tmp_file="${cache_file}.tmp"

    local result=$($func)
    local cleaned=$(clean_number "$result")
    
    echo "$cleaned" > "$tmp_file"
    mv "$tmp_file" "$cache_file"
}

# Función principal para obtener métrica (con caché)
get_metric() {
    local metric=$1
    local func=$2
    local cache_file="${CACHE_DIR}/zabbix_carbonio_mailstats_${metric}.cache"
    local now=$(date +%s)

    # Si no existe caché, ejecutar síncronamente (fallback)
    if [ ! -f "$cache_file" ]; then
        update_cache "$metric" "$func"
        cat "$cache_file"
        return
    fi
    
    # Verificar edad de caché
    local mtime=$(date -r "$cache_file" +%s)
    local age=$((now - mtime))
    
    if [ "$age" -lt "$CACHE_TTL" ]; then
        # Caché fresco, devolver
        cat "$cache_file"
    else
        # Caché caducado, devolver dato viejo y actualizar en background
        cat "$cache_file"
        ( update_cache "$metric" "$func" ) >/dev/null 2>&1 &
    fi
}

case "$1" in
    bytes_sent)
        get_metric "bytes_sent" "calc_bytes_sent"
        ;;
    bytes_received)
        get_metric "bytes_received" "calc_bytes_received"
        ;;
    sent)
        get_metric "sent" "calc_sent"
        ;;
    received)
        get_metric "received" "calc_received"
        ;;
    rejected)
        get_metric "rejected" "calc_rejected"
        ;;
    bounced)
        get_metric "bounced" "calc_bounced"
        ;;
    deferred)
        get_metric "deferred" "calc_deferred"
        ;;
    debug)
        echo "=== DEBUG INFO ==="
        echo "Log File: $MAIL_LOG"
        if [ -r "$MAIL_LOG" ]; then
            echo "Readable: YES"
        else
            echo "Readable: NO"
        fi
        echo "Date ISO: $TODAY_ISO"
        echo "Date Syslog: $TODAY_SYSLOG"
        echo "Regex: ^$LOG_DATE"
        echo "--- First 5 lines of log ---"
        head -n 5 "$MAIL_LOG"
        echo "--- Matching lines sample (first 2) ---"
        grep -E "^$LOG_DATE" "$MAIL_LOG" 2>/dev/null | head -n 2
        echo "--- Sample 'size=' lines ---"
        grep -m 2 "size=" "$MAIL_LOG"
        echo "--- Sample 'message-id=' lines ---"
        grep -m 2 "message-id=" "$MAIL_LOG"
        echo "--- Sample 'status=sent' lines ---"
        grep -m 2 "status=sent" "$MAIL_LOG"
        echo "=================="
        ;;
    *)
        echo "Uso: $0 {bytes_sent|bytes_received|sent|received|rejected|bounced|deferred|debug}"
        exit 1
        ;;
esac
