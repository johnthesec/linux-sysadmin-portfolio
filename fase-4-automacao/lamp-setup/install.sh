#!/bin/bash

# install.sh
# Instalação automatizada do stack Apache + MySQL + Python (mod_wsgi)
# Fase 4 — Linux SysAdmin Portfolio
#
# O que este script faz:
#   1. Verifica e instala dependências (apache2, mysql, python3, mod_wsgi)
#   2. Cria estrutura de diretórios do projeto
#   3. Configura Virtual Host do Apache
#   4. Cria aplicação Python de exemplo
#   5. Ativa o site e reinicia o Apache
#
# Uso:
#   sudo ./install.sh
#
# Pré-requisitos:
#   - Ubuntu 24.04 LTS
#   - Conexão com internet (para apt)
#   - Usuário com sudo

set -euo pipefail

# ─── CONFIGURAÇÃO ────────────────────────────────────────────
PROJETO_DIR="/var/www/portfolio"
VHOST_CONF="/etc/apache2/sites-available/portfolio.conf"
USUARIO="${SUDO_USER:-$USER}"

# ─── CORES ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warning() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error()   { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }

# ─── VALIDAÇÕES ──────────────────────────────────────────────
verificar_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script precisa ser executado com sudo."
    fi
}

# ─── INSTALAÇÃO DE DEPENDÊNCIAS ──────────────────────────────
instalar_dependencias() {
    info "Verificando dependências..."

    apt-get update -qq

    # Apache
    if command -v apache2 &>/dev/null; then
        warning "apache2 já instalado — pulando."
    else
        info "Instalando apache2..."
        apt-get install -y apache2
        success "apache2 instalado."
    fi

    # MySQL
    if command -v mysql &>/dev/null; then
        warning "mysql já instalado — pulando."
    else
        info "Instalando mysql-server..."
        apt-get install -y mysql-server
        success "mysql-server instalado."
    fi

    # Python3
    if command -v python3 &>/dev/null; then
        warning "python3 já instalado — pulando."
    else
        info "Instalando python3..."
        apt-get install -y python3
        success "python3 instalado."
    fi

    # mod_wsgi
    if apache2ctl -M 2>/dev/null | grep -q wsgi; then
        warning "mod_wsgi já ativo — pulando."
    else
        info "Instalando libapache2-mod-wsgi-py3..."
        apt-get install -y libapache2-mod-wsgi-py3
        success "mod_wsgi instalado e ativado."
    fi
}

# ─── ESTRUTURA DO PROJETO ────────────────────────────────────
criar_estrutura() {
    info "Criando estrutura do projeto em $PROJETO_DIR..."

    mkdir -p "$PROJETO_DIR"
    chown "$USUARIO:$USUARIO" "$PROJETO_DIR"
    success "Diretório $PROJETO_DIR criado."

    # Aplicação Python mínima
    cat > "$PROJETO_DIR/app.py" <<'EOF'
# app.py — aplicação WSGI mínima para validar o stack
# Fase 4 — Linux SysAdmin Portfolio

def application(environ, start_response):
    status = '200 OK'
    headers = [('Content-Type', 'text/html; charset=utf-8')]
    start_response(status, headers)

    body = """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <title>Stack Python funcionando</title>
    </head>
    <body>
        <h1>Stack Apache + Python funcionando!</h1>
        <p>Servidor configurado por john — Linux SysAdmin em formação.</p>
        <p>Fase 4 — Automação e Projeto Final</p>
    </body>
    </html>
    """
    return [body.encode('utf-8')]
EOF

    chown "$USUARIO:$USUARIO" "$PROJETO_DIR/app.py"
    success "Aplicação Python criada em $PROJETO_DIR/app.py"
}

# ─── VIRTUAL HOST ────────────────────────────────────────────
configurar_vhost() {
    info "Configurando Virtual Host do Apache..."

    cat > "$VHOST_CONF" <<EOF
<VirtualHost *:80>
    ServerName localhost
    ServerAdmin $USUARIO@localhost

    DocumentRoot $PROJETO_DIR

    WSGIScriptAlias / $PROJETO_DIR/app.py

    <Directory $PROJETO_DIR>
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/portfolio-error.log
    CustomLog \${APACHE_LOG_DIR}/portfolio-access.log combined
</VirtualHost>
EOF

    # Ativa o site do portfolio e desativa o padrão
    a2ensite portfolio.conf  &>/dev/null
    a2dissite 000-default.conf &>/dev/null
    success "Virtual Host configurado e ativado."
}

# ─── SERVIÇOS ────────────────────────────────────────────────
iniciar_servicos() {
    info "Iniciando serviços..."

    systemctl enable apache2 &>/dev/null
    systemctl restart apache2
    success "Apache iniciado e habilitado no boot."

    systemctl enable mysql &>/dev/null
    systemctl start mysql
    success "MySQL iniciado e habilitado no boot."
}

# ─── VALIDAÇÃO FINAL ─────────────────────────────────────────
validar_instalacao() {
    echo ""
    info "Validando instalação..."

    # Apache respondendo
    if curl -s http://localhost | grep -q "Stack Apache"; then
        success "Apache servindo aplicação Python corretamente."
    else
        warning "Apache não respondeu como esperado — verifique os logs em /var/log/apache2/"
    fi

    # MySQL rodando
    if systemctl is-active --quiet mysql; then
        success "MySQL rodando."
    else
        warning "MySQL não está ativo."
    fi

    echo ""
    success "Instalação concluída!"
    info "Acesse: http://localhost"
    info "Logs Apache: /var/log/apache2/portfolio-error.log"
    info "MySQL: sudo mysql"
    echo ""
}

# ─── PONTO DE ENTRADA ────────────────────────────────────────
verificar_root
instalar_dependencias
criar_estrutura
configurar_vhost
iniciar_servicos
validar_instalacao
