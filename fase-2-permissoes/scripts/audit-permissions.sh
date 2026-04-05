#!/bin/bash

# audit-permissions.sh
# Auditoria de arquivos world-writable e SUID no sistema
# Uso: ./audit-permissions.sh

set -euo pipefail

PASTAS_AUDIT=("/home" "/tmp" "/usr/bin" "/usr/sbin" "/bin")

echo "================================================"
echo "  AUDITORIA DE PERMISSÕES - $(date '+%Y-%m-%d %H:%M')"
echo "================================================"
echo ""

echo "[1] Arquivos world-writable (o+w):"
echo "    Risco: qualquer usuário do sistema pode modificar"
echo ""

ENCONTRADOS=0
for PASTA in "${PASTAS_AUDIT[@]}"; do
    RESULTADO=$(find "$PASTA" -perm -o+w -type f 2>/dev/null)
    if [ -n "$RESULTADO" ]; then
        echo "$RESULTADO"
        ENCONTRADOS=1
    fi
done

if [ "$ENCONTRADOS" -eq 0 ]; then
    echo "    Nenhum arquivo world-writable encontrado. ✅"
fi

echo ""

echo "[2] Arquivos com bit SUID (-perm -4000):"
echo "    Risco: executam com privilégios do dono (geralmente root)"
echo ""

for PASTA in "${PASTAS_AUDIT[@]}"; do
    find "$PASTA" -perm -4000 -type f 2>/dev/null | while read -r ARQUIVO; do
        ls -l "$ARQUIVO"
    done
done

echo ""
echo "================================================"
echo "  AUDITORIA CONCLUÍDA"
echo "================================================"
echo ""
echo "Como corrigir world-writable:"
echo "  chmod o-w /caminho/do/arquivo"
echo ""
echo "Como investigar SUID suspeito:"
echo "  ls -l /caminho/do/arquivo"
echo "  which nome-do-arquivo"
