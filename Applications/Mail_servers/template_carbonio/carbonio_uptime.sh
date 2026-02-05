#!/bin/bash
# =============================================================================
# carbonio_uptime.sh - Uptime de servicios Carbonio
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_uptime.sh
# =============================================================================

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

# Función para obtener uptime usando fecha de inicio del servicio
get_service_uptime() {
    local service=$1
    
    # Verificar si el servicio está activo
    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        echo 0
        return
    fi
    
    # Obtener el timestamp de inicio
    local start_time
    start_time=$(systemctl show "$service" --property=ActiveEnterTimestamp 2>/dev/null | cut -d'=' -f2)
    
    if [ -z "$start_time" ] || [ "$start_time" = "n/a" ] || [ "$start_time" = "" ]; then
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
    
    local diff=$((now_epoch - start_epoch))
    clean_number "$diff"
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
