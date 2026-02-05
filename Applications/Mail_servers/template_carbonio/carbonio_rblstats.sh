#!/bin/bash
# =============================================================================
# carbonio_rblstats.sh - Estadísticas de bloqueos RBL/Antispam
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_rblstats.sh
# Compatible con Ubuntu 24.04 (formato de fecha ISO 8601)
# =============================================================================

# Ruta del log de Postfix
MAIL_LOG="/var/log/mail.log"

# Alternativas de ubicación del log
if [ ! -f "$MAIL_LOG" ]; then
    MAIL_LOG="/var/log/carbonio/postfix.log"
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
    # Listas RBL específicas
    zen.spamhaus.org|dbl.spamhaus.org|bl.spamcop.net|b.barracudacentral.org|psbl.surriel.com)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "blocked using $1")
        clean_number "$result"
        ;;
    
    # Bloqueos por DNS reverso
    reverse_hostname)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "reverse hostname")
        clean_number "$result"
        ;;
    
    # Rechazos HELO inválido
    helo_invalid)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "Helo command rejected: need fully-qualified hostname")
        clean_number "$result"
        ;;
    
    # Rechazos HELO host no encontrado
    helo_notfound)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "Helo command rejected: Host not found")
        clean_number "$result"
        ;;
    
    # Total de bloqueos RBL (cualquier lista)
    total_rbl)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "blocked using")
        clean_number "$result"
        ;;
    
    # Total de rechazos
    total_reject)
        result=$(grep "^$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "NOQUEUE: reject")
        clean_number "$result"
        ;;
    
    *)
        echo "Uso: $0 {zen.spamhaus.org|dbl.spamhaus.org|bl.spamcop.net|b.barracudacentral.org|psbl.surriel.com|reverse_hostname|helo_invalid|helo_notfound|total_rbl|total_reject}"
        exit 1
        ;;
esac
