#!/bin/bash

# backup.sh
# Copia arquivos de configuração importantes com timestamp
# Uso: ./backup.sh
#
# O que faz:
#   - Cria um diretório de backup com data e hora
#   - Copia arquivos de config selecionados
#   - Exibe resumo do que foi salvo

set -euo pipefail

# ─── CONFIGURAÇÃO ────────────────────────────────────────────
DESTINO="$HOME/backups/config-$(date '+%Y-%m-%d_%H-%M-%S')"
ARQUIVOS=(
    "/etc/hosts"
    "/etc/hostname"
    "/etc/bash.bashrc"
)

# ─── CORES ───────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error()   { echo -e "${RED}[ERRO]${NC} $1"; }

# ─── BACKUP ──────────────────────────────────────────────────
info "Criando diretório de backup: $DESTINO"
mkdir -p "$DESTINO"

for ARQUIVO in "${ARQUIVOS[@]}"; do
    if [[ -f "$ARQUIVO" ]]; then
        cp "$ARQUIVO" "$DESTINO/"
        success "Copiado: $ARQUIVO"
    else
        error "Não encontrado: $ARQUIVO"
    fi
done

echo ""
info "Arquivos salvos em $DESTINO:"
ls -lh "$DESTINO"
echo ""
success "Backup concluído!"
