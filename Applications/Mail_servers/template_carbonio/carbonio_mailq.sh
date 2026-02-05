#!/bin/bash
# =============================================================================
# carbonio_mailq.sh - Estadísticas de colas de correo Postfix
# Ubicación: /etc/zabbix/scripts/carbonio/carbonio_mailq.sh
# =============================================================================

# Rutas de Postfix en Carbonio
POSTFIX_SPOOL="/opt/zextras/data/postfix/spool"
MAILQ_CMD="/opt/zextras/common/sbin/mailq"
POSTQUEUE_CMD="/opt/zextras/common/sbin/postqueue"

case "$1" in
    total)
        # Total de mensajes en cola
        if [ -x "$MAILQ_CMD" ]; then
            $MAILQ_CMD 2>/dev/null | grep -v "Mail queue is empty" | grep -c '^[0-9A-F]' || echo 0
        else
            echo 0
        fi
        ;;
    
    active)
        # Mensajes activos (en proceso de envío)
        if [ -d "$POSTFIX_SPOOL/active" ]; then
            find "$POSTFIX_SPOOL/active" -type f 2>/dev/null | wc -l
        else
            # Alternativa: contar en output de postqueue
            if [ -x "$POSTQUEUE_CMD" ]; then
                $POSTQUEUE_CMD -p 2>/dev/null | grep -c "^\*" || echo 0
            else
                echo 0
            fi
        fi
        ;;
    
    deferred)
        # Mensajes diferidos (reintentando)
        if [ -d "$POSTFIX_SPOOL/deferred" ]; then
            find "$POSTFIX_SPOOL/deferred" -type f 2>/dev/null | wc -l
        else
            echo 0
        fi
        ;;
    
    hold)
        # Mensajes en espera (requieren intervención)
        if [ -d "$POSTFIX_SPOOL/hold" ]; then
            find "$POSTFIX_SPOOL/hold" -type f 2>/dev/null | wc -l
        else
            echo 0
        fi
        ;;
    
    corrupt)
        # Mensajes corruptos
        if [ -d "$POSTFIX_SPOOL/corrupt" ]; then
            find "$POSTFIX_SPOOL/corrupt" -type f 2>/dev/null | wc -l
        else
            echo 0
        fi
        ;;
    
    incoming)
        # Mensajes entrantes
        if [ -d "$POSTFIX_SPOOL/incoming" ]; then
            find "$POSTFIX_SPOOL/incoming" -type f 2>/dev/null | wc -l
        else
            echo 0
        fi
        ;;
    
    maildrop)
        # Mensajes locales pendientes
        if [ -d "$POSTFIX_SPOOL/maildrop" ]; then
            find "$POSTFIX_SPOOL/maildrop" -type f 2>/dev/null | wc -l
        else
            echo 0
        fi
        ;;
    
    *)
        echo "Uso: $0 {total|active|deferred|hold|corrupt|incoming|maildrop}"
        exit 1
        ;;
esac
