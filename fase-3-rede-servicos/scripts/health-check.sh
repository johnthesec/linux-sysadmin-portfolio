#!/bin/bash

# health-check.sh
# Monitora o estado do servidor: RAM, disco e serviços
# Uso: ./health-check.sh
#
# Opcoes:
#   -s    Verificar só serviços
#   -r    Verificar só recursos (RAM e disco)
#   -h    Mostrar ajuda

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[FALHA]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Serviços a monitorar — edite conforme seu servidor
SERVICOS=("nginx" "ssh")

# Limites de alerta
DISCO_LIMITE=80   # % de uso do disco
RAM_LIMITE=500    # MB mínimo disponível

mostrar_ajuda() {
    echo ""
    echo "Uso: ./health-check.sh [opcao]"
    echo ""
    echo "Opcoes:"
    echo "  -s    Verificar so servicos"
    echo "  -r    Verificar so recursos (RAM e disco)"
    echo "  -h    Mostrar esta ajuda"
    echo ""
}

checar_recursos() {
    echo ""
    info "Recursos do sistema:"
    echo ""

    # RAM
    RAM_LIVRE=$(free -m | awk '/Mem:/ {print $7}')
    RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USO=$(free -m | awk '/Mem:/ {print $3}')

    if [[ $RAM_LIVRE -lt $RAM_LIMITE ]]; then
        warn "RAM disponivel: ${RAM_LIVRE}MB de ${RAM_TOTAL}MB — pouca memória livre!"
    else
        ok "RAM disponivel: ${RAM_LIVRE}MB de ${RAM_TOTAL}MB (usado: ${RAM_USO}MB)"
    fi

    # Disco
    DISCO_USO=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    DISCO_LIVRE=$(df -h / | awk 'NR==2 {print $4}')
    DISCO_TOTAL=$(df -h / | awk 'NR==2 {print $2}')

    if [[ $DISCO_USO -gt $DISCO_LIMITE ]]; then
        fail "Disco em ${DISCO_USO}% de uso (livre: ${DISCO_LIVRE} de ${DISCO_TOTAL}) — atencao!"
    else
        ok "Disco em ${DISCO_USO}% de uso (livre: ${DISCO_LIVRE} de ${DISCO_TOTAL})"
    fi
    echo ""
}

checar_servicos() {
    echo ""
    info "Status dos servicos:"
    echo ""

    for SERVICO in "${SERVICOS[@]}"; do
        if systemctl is-active --quiet "$SERVICO"; then
            ok "$SERVICO esta rodando"
        else
            fail "$SERVICO esta parado!"
        fi
    done
    echo ""
}

checar_tudo() {
    echo "================================"
    echo "  HEALTH CHECK — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Servidor: $(hostname)"
    echo "================================"

    checar_recursos
    checar_servicos

    echo "================================"
    echo ""
}

# Ponto de entrada
if [[ $# -eq 0 ]]; then
    checar_tudo
    exit 0
fi

case "$1" in
    -s) checar_servicos ;;
    -r) checar_recursos ;;
    -h) mostrar_ajuda ;;
    *)  echo -e "${RED}[ERRO]${NC} Opcao invalida: $1. Use -h para ver as opcoes." ;;
esac
