#!/bin/bash
# =============================================================================
# carbonio_accounts.sh - Estadísticas de cuentas y dominios
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_accounts.sh
# =============================================================================

# Comando carbonio
CARBONIO_CMD="/opt/zextras/bin/carbonio"

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
if [ ! -x "$CARBONIO_CMD" ]; then
    echo 0
    exit 0
fi

case "$1" in
    total)
        # Total de cuentas
        result=$($CARBONIO_CMD prov -l gaa 2>/dev/null | wc -l)
        clean_number "$result"
        ;;
    
    active)
        # Cuentas activas (no bloqueadas) - método simplificado
        # Contamos todas las cuentas con status active
        result=$($CARBONIO_CMD prov -l gaa 2>/dev/null | head -100 | while read account; do
            if [ -n "$account" ]; then
                status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
                if [ "$status" = "active" ]; then
                    echo "1"
                fi
            fi
        done | wc -l)
        clean_number "$result"
        ;;
    
    locked)
        # Cuentas bloqueadas
        result=$($CARBONIO_CMD prov -l gaa 2>/dev/null | head -100 | while read account; do
            if [ -n "$account" ]; then
                status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
                if [ "$status" = "locked" ] || [ "$status" = "lockout" ]; then
                    echo "1"
                fi
            fi
        done | wc -l)
        clean_number "$result"
        ;;
    
    closed)
        # Cuentas cerradas
        result=$($CARBONIO_CMD prov -l gaa 2>/dev/null | head -100 | while read account; do
            if [ -n "$account" ]; then
                status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
                if [ "$status" = "closed" ]; then
                    echo "1"
                fi
            fi
        done | wc -l)
        clean_number "$result"
        ;;
    
    domains)
        # Total de dominios
        result=$($CARBONIO_CMD prov -l gad 2>/dev/null | wc -l)
        clean_number "$result"
        ;;
    
    cos)
        # Total de COS (Classes of Service)
        result=$($CARBONIO_CMD prov -l gac 2>/dev/null | wc -l)
        clean_number "$result"
        ;;
    
    *)
        echo "Uso: $0 {total|active|locked|closed|domains|cos}"
        exit 1
        ;;
esac
