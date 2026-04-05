#!/bin/bash

# gerenciar-acesso.sh
# Cria grupos, aplica e revoga permissões de acesso
# Uso: sudo ./gerenciar-acesso.sh [flag]

set -euo pipefail

GRUPO="sysadmins"
USUARIO="teste-user"
ARQUIVO="$HOME/meu-script.sh"

mostrar_ajuda() {
    echo "Uso: sudo $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  -c    Criar grupo e usuário de teste"
    echo "  -a    Aplicar permissões de acesso compartilhado"
    echo "  -r    Revogar acesso do usuário de teste"
    echo "  -l    Listar permissões atuais"
    echo "  -h    Mostrar esta ajuda"
}

criar_ambiente() {
    echo "[+] Criando usuário e grupo de teste..."
    sudo groupadd "$GRUPO" 2>/dev/null || echo "  Grupo $GRUPO já existe"
    sudo useradd -m "$USUARIO" 2>/dev/null || echo "  Usuário $USUARIO já existe"
    sudo usermod -aG "$GRUPO" john
    sudo usermod -aG "$GRUPO" "$USUARIO"
    echo '#!/bin/bash' > "$ARQUIVO"
    echo 'echo "Script rodando!"' >> "$ARQUIVO"
    chmod 700 "$ARQUIVO"
    echo "[+] Ambiente criado."
    getent group "$GRUPO"
}

aplicar_permissoes() {
    echo "[+] Aplicando permissões compartilhadas..."
    sudo chown john:"$GRUPO" "$ARQUIVO"
    sudo chown john:"$GRUPO" "$HOME"
    chmod 750 "$ARQUIVO"
    echo "[+] Permissões aplicadas:"
    ls -l "$ARQUIVO"
}

revogar_acesso() {
    echo "[+] Revogando acesso do $USUARIO..."
    sudo gpasswd -d "$USUARIO" "$GRUPO"
    sudo chown john:john "$HOME"
    sudo chown john:john "$ARQUIVO"
    echo "[+] Acesso revogado."
    getent group "$GRUPO"
}

listar_permissoes() {
    echo "[*] Permissões atuais:"
    ls -l "$ARQUIVO" 2>/dev/null || echo "  Arquivo não encontrado"
    ls -ld "$HOME"
    echo ""
    echo "[*] Membros do grupo $GRUPO:"
    getent group "$GRUPO" 2>/dev/null || echo "  Grupo não existe"
}

if [ $# -eq 0 ]; then
    mostrar_ajuda
    exit 0
fi

case "$1" in
    -c) criar_ambiente ;;
    -a) aplicar_permissoes ;;
    -r) revogar_acesso ;;
    -l) listar_permissoes ;;
    -h) mostrar_ajuda ;;
    *)  echo "Opção inválida: $1"; mostrar_ajuda; exit 1 ;;
esac
