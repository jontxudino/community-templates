#!/bin/bash
# =============================================================================
# carbonio_accounts.sh - Estadísticas de cuentas y dominios
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_accounts.sh
# Versión: 1.2 (con caché)
# =============================================================================

# Configuración
CACHE_DIR="/tmp"
CACHE_TTL=600  # 10 minutos
CARBONIO_BIN="/opt/zextras/bin/carbonio"
CARBONIO_CMD="sudo -u zextras $CARBONIO_BIN"

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

# Verificar que existe el comando
if [ ! -x "$CARBONIO_BIN" ]; then
    echo 0
    exit 0
fi

# Funciones de cálculo para cada métrica
calc_total() {
    # Total de cuentas (filtrando por @)
    $CARBONIO_CMD prov -l gaa 2>/dev/null | grep "@" | wc -l
}

calc_active() {
    # Cuentas activas
    $CARBONIO_CMD prov -l gaa 2>/dev/null | grep "@" | while read account; do
        if [ -n "$account" ]; then
            status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
            if [ "$status" = "active" ]; then
                echo "1"
            fi
        fi
    done | wc -l
}

calc_locked() {
    # Cuentas bloqueadas
    $CARBONIO_CMD prov -l gaa 2>/dev/null | grep "@" | while read account; do
        if [ -n "$account" ]; then
            status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
            if [ "$status" = "locked" ] || [ "$status" = "lockout" ]; then
                echo "1"
            fi
        fi
    done | wc -l
}

calc_closed() {
    # Cuentas cerradas
    $CARBONIO_CMD prov -l gaa 2>/dev/null | grep "@" | while read account; do
        if [ -n "$account" ]; then
            status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
            if [ "$status" = "closed" ]; then
                echo "1"
            fi
        fi
    done | wc -l
}

calc_domains() {
    # Total de dominios
    $CARBONIO_CMD prov -l gad 2>/dev/null | wc -l
}

calc_cos() {
    # Total de COS
    $CARBONIO_CMD prov -l gac 2>/dev/null | wc -l
}

# Función para actualizar caché
update_cache() {
    local metric=$1
    local func=$2
    local cache_file="${CACHE_DIR}/zabbix_carbonio_${metric}.cache"
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
    local cache_file="${CACHE_DIR}/zabbix_carbonio_${metric}.cache"
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
    total)
        get_metric "total" "calc_total"
        ;;
    active)
        get_metric "active" "calc_active"
        ;;
    locked)
        get_metric "locked" "calc_locked"
        ;;
    closed)
        get_metric "closed" "calc_closed"
        ;;
    domains)
        get_metric "domains" "calc_domains"
        ;;
    cos)
        get_metric "cos" "calc_cos"
        ;;
    *)
        echo "Uso: $0 {total|active|locked|closed|domains|cos}"
        exit 1
        ;;
esac
