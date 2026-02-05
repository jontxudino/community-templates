# Template Zabbix para Carbonio Mail Server (Ubuntu 24.04+)

## Descripción

Este template está diseñado para monitorizar servidores **Carbonio** en **Ubuntu 24.04+**, donde el comando `zmcontrol` ha sido reemplazado por `systemctl`.

### Cambios en Ubuntu 24.04+

A partir de Ubuntu 24.04, Carbonio gestiona todos sus servicios mediante **systemd**:

| Servicio antiguo    | Nuevo servicio/target              |
|---------------------|------------------------------------|
| amavis/spamassassin | carbonio-mailthreat.service        |
| clamav              | carbonio-antivirus.service         |
| cbpolicyd           | carbonio-policyd.service           |
| configd             | carbonio-configd.service           |
| freshclam           | carbonio-freshclam.service         |
| memcache            | carbonio-memcached.service         |
| mta                 | carbonio-mta.target                |
| mysql               | carbonio-appserver-db.service      |
| nginx               | carbonio-nginx.service             |
| opendkim            | carbonio-opendkim.service          |
| ldap                | carbonio-openldap.service          |
| postfix             | carbonio-postfix.service           |
| proxy               | carbonio-proxy.target              |
| stats               | carbonio-stats.service             |
| zmmailbox           | carbonio-appserver.service         |

### Targets disponibles

- `carbonio-appserver.target`
- `carbonio-directory-server.target`
- `carbonio-mta.target`
- `carbonio-proxy.target`

## Métricas incluidas

### Estado de servicios
- Todos los servicios individuales de Carbonio
- Targets de systemd (MTA, Proxy, AppServer, Directory)
- Número de servicios activos

### Colas de correo (Postfix)
- Cola total
- Cola activa
- Cola diferida
- Cola en espera (hold)
- Cola corrupta
- Cola entrante

### Estadísticas de correo
- Bytes enviados/recibidos (diario)
- Mensajes enviados/recibidos (diario)
- Mensajes rechazados/rebotados (diario)

### Anti-Spam / RBL
- Bloqueos por Spamhaus ZEN y DBL
- Bloqueos por SpamCop
- Bloqueos por Barracuda
- Bloqueos por PSBL
- Bloqueos por DNS reverso
- Rechazos HELO inválidos

### Almacenamiento
- Espacio usado/libre en store
- Porcentaje de uso

### Conexiones
- Conexiones IMAP activas
- Conexiones POP3 activas
- Conexiones SMTP activas
- Conexiones HTTP/HTTPS activas

### Cuentas
- Total de cuentas
- Cuentas activas
- Total de dominios

### Información del sistema
- Versión de Carbonio
- Uptime del AppServer

## Instalación

### 1. Requisitos previos

- Zabbix Agent instalado en el servidor Carbonio
- Zabbix Server 6.0 o superior
- Ubuntu 24.04 o superior con Carbonio instalado

### 2. Copiar archivos

```bash
# Crear directorio de scripts
sudo mkdir -p /etc/zabbix/scripts/carbonio

# Copiar UserParameter
sudo cp userparameter_carbonio.conf /etc/zabbix/zabbix_agentd.d/

# Copiar scripts
sudo cp scripts/*.sh /etc/zabbix/scripts/carbonio/

# Dar permisos de ejecución
sudo chmod +x /etc/zabbix/scripts/carbonio/*.sh
```

### 3. Configurar sudoers

Añadir al archivo `/etc/sudoers.d/zabbix`:

```sudoers
# Permisos para monitorización de Carbonio
zabbix ALL=(ALL) NOPASSWD: /usr/bin/systemctl status carbonio-*
zabbix ALL=(ALL) NOPASSWD: /usr/bin/systemctl is-active carbonio-*
zabbix ALL=(ALL) NOPASSWD: /usr/bin/systemctl show carbonio-*
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/postqueue
zabbix ALL=(ALL) NOPASSWD: /opt/zextras/common/sbin/mailq
zabbix ALL=(ALL) NOPASSWD: /opt/zextras/common/sbin/postqueue
zabbix ALL=(ALL) NOPASSWD: /opt/zextras/bin/carbonio
zabbix ALL=(ALL) NOPASSWD: /etc/zabbix/scripts/carbonio/*.sh
```

Verificar sintaxis:
```bash
sudo visudo -cf /etc/sudoers.d/zabbix
```

### 4. Verificar permisos de lectura de logs

El usuario `zabbix` necesita leer `/var/log/mail.log`:

```bash
# Opción 1: Añadir usuario zabbix al grupo adm
sudo usermod -aG adm zabbix

# Opción 2: Crear regla de logrotate con permisos
# (ya suele estar configurado en Ubuntu)
```

### 5. Reiniciar agente Zabbix

```bash
sudo systemctl restart zabbix-agent
```

### 6. Verificar funcionamiento

```bash
# Probar métricas manualmente
zabbix_agentd -t carbonio.postfix.status
zabbix_agentd -t carbonio.mailq.total
zabbix_agentd -t carbonio.services.active
```

### 7. Importar template en Zabbix Server

1. Ir a **Configuración → Templates**
2. Click en **Importar**
3. Seleccionar el archivo `template_carbonio_ubuntu24_complete.yaml`
4. Click en **Importar**

### 8. Asignar template al host

1. Ir a **Configuración → Hosts**
2. Seleccionar el host del servidor Carbonio
3. En la pestaña **Templates**, añadir el template **Carbonio**
4. Click en **Actualizar**

## Configuración de macros

El template incluye las siguientes macros configurables:

| Macro                      | Valor por defecto      | Descripción                           |
|----------------------------|------------------------|---------------------------------------|
| `{$CARBONIO.MAILQ.WARN}`   | 100                    | Umbral de advertencia cola de correo  |
| `{$CARBONIO.MAILQ.HIGH}`   | 500                    | Umbral alto cola de correo            |
| `{$CARBONIO.MAILQ.CRIT}`   | 1000                   | Umbral crítico cola de correo         |
| `{$CARBONIO.STORE.PATH}`   | /opt/zextras/store     | Ruta del almacenamiento de buzones    |
| `{$CARBONIO.LOG.PATH}`     | /var/log/carbonio      | Ruta de logs de Carbonio              |

Para personalizar los umbrales:

1. Ir a **Configuración → Hosts**
2. Seleccionar el host
3. Ir a la pestaña **Macros**
4. Añadir o modificar las macros heredadas

## Troubleshooting

### El agente no devuelve datos

```bash
# Verificar que el agente puede ejecutar los comandos
sudo -u zabbix /etc/zabbix/scripts/carbonio/carbonio_mailstats.sh sent

# Verificar permisos de sudoers
sudo -u zabbix sudo systemctl is-active carbonio-postfix.service
```

### Los scripts no devuelven datos de logs

```bash
# Verificar que existe el log y zabbix puede leerlo
sudo -u zabbix cat /var/log/mail.log | head

# Verificar formato de fecha en logs
grep "$(date +'%b %e')" /var/log/mail.log | head
```

### Error "Permission denied" en systemctl

```bash
# Verificar PolicyKit o añadir usuario a grupo systemd-journal
sudo usermod -aG systemd-journal zabbix
```

## Estructura de archivos

```
/etc/zabbix/
├── zabbix_agentd.d/
│   └── userparameter_carbonio.conf    # Configuración de UserParameter
└── scripts/
    └── carbonio/
        ├── carbonio_mailstats.sh      # Estadísticas de correo
        ├── carbonio_rblstats.sh       # Estadísticas RBL/Antispam
        ├── carbonio_mailq.sh          # Colas de correo
        ├── carbonio_accounts.sh       # Cuentas y dominios
        └── carbonio_uptime.sh         # Uptime de servicios
```

## Referencias

- [Carbonio zmcontrol death - Ubuntu 24.04](https://www.anahuac.eu/carbonio-zmcontrol-death/)
- [Zabbix Community Templates - Zimbra](https://github.com/zabbix/community-templates/tree/main/Applications/Mail_servers/template_zimbra_collaboration)
- [Documentación oficial Carbonio](https://docs.zextras.com/)

## Autor

Template creado por Jon Oliveira
Adaptación de Zimbra a Carbonio Ubuntu 24.04+

---

**Nota**: Este template está diseñado específicamente para la nueva arquitectura de Carbonio en Ubuntu 24.04+. Para versiones anteriores que aún usen `zmcontrol`, se requiere un template diferente.
