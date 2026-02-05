#!/bin/bash
# =============================================================================
# carbonio_rblstats.sh - Estadísticas de bloqueos RBL/Antispam
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_rblstats.sh
# =============================================================================

# Ruta del log de Postfix
MAIL_LOG="/var/log/mail.log"

# Alternativas de ubicación del log
if [ ! -f "$MAIL_LOG" ]; then
    MAIL_LOG="/var/log/carbonio/postfix.log"
fi

# Verificar que existe el log
if [ ! -f "$MAIL_LOG" ]; then
    echo 0
    exit 0
fi

# Fecha de hoy para filtrar últimas 24h
TODAY=$(date +%b\ %e)

case "$1" in
    # Listas RBL específicas
    zen.spamhaus.org|dbl.spamhaus.org|bl.spamcop.net|b.barracudacentral.org|psbl.surriel.com)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "blocked using $1" || echo 0
        ;;
    
    # Bloqueos por DNS reverso
    reverse_hostname)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "reverse hostname" || echo 0
        ;;
    
    # Rechazos HELO inválido
    helo_invalid)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "Helo command rejected: need fully-qualified hostname" || echo 0
        ;;
    
    # Rechazos HELO host no encontrado
    helo_notfound)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "Helo command rejected: Host not found" || echo 0
        ;;
    
    # Total de bloqueos RBL (cualquier lista)
    total_rbl)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "blocked using" || echo 0
        ;;
    
    # Total de rechazos
    total_reject)
        grep "$TODAY" "$MAIL_LOG" 2>/dev/null | grep -c "NOQUEUE: reject" || echo 0
        ;;
    
    *)
        echo "Uso: $0 {zen.spamhaus.org|dbl.spamhaus.org|bl.spamcop.net|b.barracudacentral.org|psbl.surriel.com|reverse_hostname|helo_invalid|helo_notfound|total_rbl|total_reject}"
        exit 1
        ;;
esac
