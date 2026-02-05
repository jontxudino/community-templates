#!/bin/bash
# =============================================================================
# carbonio_uptime.sh - Uptime de servicios Carbonio
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_uptime.sh
# =============================================================================

# Función para convertir tiempo de systemd a segundos
systemd_uptime_to_seconds() {
    local service=$1
    local uptime_str
    
    # Obtener la línea de Active desde systemctl status
    uptime_str=$(systemctl status "$service" 2>/dev/null | grep "Active:" | grep -oP 'since.*;\s*\K[^;]+')
    
    if [ -z "$uptime_str" ]; then
        echo 0
        return
    fi
    
    # Extraer componentes de tiempo (formatos posibles: "1h 30min ago", "2 days 3h ago", etc.)
    local days=0 hours=0 mins=0 secs=0
    
    if [[ "$uptime_str" =~ ([0-9]+)\ *day ]]; then
        days=${BASH_REMATCH[1]}
    fi
    if [[ "$uptime_str" =~ ([0-9]+)\ *h ]]; then
        hours=${BASH_REMATCH[1]}
    fi
    if [[ "$uptime_str" =~ ([0-9]+)\ *min ]]; then
        mins=${BASH_REMATCH[1]}
    fi
    if [[ "$uptime_str" =~ ([0-9]+)\ *s ]]; then
        secs=${BASH_REMATCH[1]}
    fi
    
    # Calcular total en segundos
    echo $(( days*86400 + hours*3600 + mins*60 + secs ))
}

# Función alternativa usando fecha de inicio del servicio
get_service_uptime() {
    local service=$1
    
    # Obtener el timestamp de inicio
    local start_time
    start_time=$(systemctl show "$service" --property=ActiveEnterTimestamp 2>/dev/null | cut -d'=' -f2)
    
    if [ -z "$start_time" ] || [ "$start_time" = "n/a" ]; then
        echo 0
        return
    fi
    
    # Convertir a epoch
    local start_epoch
    start_epoch=$(date -d "$start_time" +%s 2>/dev/null)
    
    if [ -z "$start_epoch" ]; then
        echo 0
        return
    fi
    
    # Calcular diferencia
    local now_epoch
    now_epoch=$(date +%s)
    
    echo $(( now_epoch - start_epoch ))
}

case "$1" in
    appserver)
        get_service_uptime "carbonio-appserver.service"
        ;;
    
    postfix)
        get_service_uptime "carbonio-postfix.service"
        ;;
    
    nginx)
        get_service_uptime "carbonio-nginx.service"
        ;;
    
    openldap)
        get_service_uptime "carbonio-openldap.service"
        ;;
    
    mysql)
        get_service_uptime "carbonio-appserver-db.service"
        ;;
    
    memcached)
        get_service_uptime "carbonio-memcached.service"
        ;;
    
    amavis)
        get_service_uptime "carbonio-mailthreat.service"
        ;;
    
    clamav)
        get_service_uptime "carbonio-antivirus.service"
        ;;
    
    *)
        echo "Uso: $0 {appserver|postfix|nginx|openldap|mysql|memcached|amavis|clamav}"
        exit 1
        ;;
esac
