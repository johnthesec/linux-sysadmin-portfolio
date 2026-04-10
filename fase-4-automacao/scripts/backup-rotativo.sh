#!/bin/bash

# backup-rotativo.sh
# Realiza backup compactado de um diretório com rotação de 7 dias
# Uso: ./backup-rotativo.sh
#
# Configuração:
#   ORIGEM   → diretório a ser copiado
#   DESTINO  → onde os backups serão salvos
#   RETENCAO → quantos dias manter (padrão: 7)

set -euo pipefail

# ─── CONFIGURAÇÃO ────────────────────────────────────────────
ORIGEM="$HOME/dados-importantes"
DESTINO="$HOME/backups"
RETENCAO=7
LOG="$DESTINO/backup.log"

# ─── CORES ───────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG"; }
success() { echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG"; }
error()   { echo -e "${RED}[ERRO]${NC} $1" | tee -a "$LOG"; exit 1; }

# ─── VALIDAÇÕES ──────────────────────────────────────────────
[[ ! -d "$ORIGEM" ]]  && error "Diretório de origem não encontrado: $ORIGEM"
[[ ! -d "$DESTINO" ]] && error "Diretório de destino não encontrado: $DESTINO"

# ─── BACKUP ──────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
ARQUIVO="$DESTINO/backup-$TIMESTAMP.tar.gz"

info "Iniciando backup em $(date '+%Y-%m-%d %H:%M:%S')"
info "Origem:  $ORIGEM"
info "Destino: $ARQUIVO"

tar -czf "$ARQUIVO" -C "$(dirname "$ORIGEM")" "$(basename "$ORIGEM")"
success "Backup criado: $(basename "$ARQUIVO")"

# ─── ROTAÇÃO ─────────────────────────────────────────────────
info "Removendo backups com mais de $RETENCAO dias..."

REMOVIDOS=0
while IFS= read -r arquivo; do
    rm "$arquivo"
    info "Removido: $(basename "$arquivo")"
    ((REMOVIDOS++))
done < <(find "$DESTINO" -name "backup-*.tar.gz" -mtime +$RETENCAO)

if [[ $REMOVIDOS -eq 0 ]]; then
    info "Nenhum backup antigo para remover."
else
    success "$REMOVIDOS backup(s) antigo(s) removido(s)."
fi

# ─── RESUMO ──────────────────────────────────────────────────
TOTAL=$(find "$DESTINO" -name "backup-*.tar.gz" | wc -l)
TAMANHO=$(du -sh "$ARQUIVO" | cut -f1)

echo ""
success "Backup concluído!"
info "Tamanho do arquivo: $TAMANHO"
info "Total de backups armazenados: $TOTAL"
info "Log em: $LOG"
echo ""
