#!/bin/bash
# =============================================================================
# carbonio_accounts.sh - Estadísticas de cuentas y dominios
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_accounts.sh
# =============================================================================

# Comando carbonio
CARBONIO_CMD="/opt/zextras/bin/carbonio"

# Verificar que existe el comando
if [ ! -x "$CARBONIO_CMD" ]; then
    echo 0
    exit 0
fi

case "$1" in
    total)
        # Total de cuentas
        $CARBONIO_CMD prov -l gaa 2>/dev/null | wc -l || echo 0
        ;;
    
    active)
        # Cuentas activas (no bloqueadas)
        $CARBONIO_CMD prov -l gaa 2>/dev/null | while read account; do
            status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
            if [ "$status" = "active" ]; then
                echo "$account"
            fi
        done | wc -l || echo 0
        ;;
    
    locked)
        # Cuentas bloqueadas
        $CARBONIO_CMD prov -l gaa 2>/dev/null | while read account; do
            status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
            if [ "$status" = "locked" ] || [ "$status" = "lockout" ]; then
                echo "$account"
            fi
        done | wc -l || echo 0
        ;;
    
    closed)
        # Cuentas cerradas
        $CARBONIO_CMD prov -l gaa 2>/dev/null | while read account; do
            status=$($CARBONIO_CMD prov ga "$account" zimbraAccountStatus 2>/dev/null | grep "zimbraAccountStatus:" | awk '{print $2}')
            if [ "$status" = "closed" ]; then
                echo "$account"
            fi
        done | wc -l || echo 0
        ;;
    
    domains)
        # Total de dominios
        $CARBONIO_CMD prov -l gad 2>/dev/null | wc -l || echo 0
        ;;
    
    cos)
        # Total de COS (Classes of Service)
        $CARBONIO_CMD prov -l gac 2>/dev/null | wc -l || echo 0
        ;;
    
    *)
        echo "Uso: $0 {total|active|locked|closed|domains|cos}"
        exit 1
        ;;
esac
