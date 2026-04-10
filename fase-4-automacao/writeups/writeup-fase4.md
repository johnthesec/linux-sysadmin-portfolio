# Automação com cron e backup rotativo no Linux

> **Fase:** Fase 4 — Automação & Projeto Final
> **Tipo:** `writeup`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-09

---

## 🎯 Objetivo

Aprender a agendar tarefas automáticas com `cron` e implementar um sistema de backup rotativo com retenção de 7 dias — cobrindo o ciclo completo de automação usado em servidores reais.

---

## 🧠 Contexto

Em produção, nenhum sysadmin faz backup manualmente todo dia. O `cron` é o agendador nativo do Linux — permite executar qualquer script em horários definidos, sem intervenção humana. Combinado com um script de backup bem escrito, garante que dados críticos sejam preservados e que backups antigos sejam removidos automaticamente para não encher o disco.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário utilizado | `john` |
| Diretório de origem | `~/dados-importantes` |
| Diretório de backups | `~/backups` |
| Retenção | 7 dias |

---

## 📋 Passo a passo

### Passo 1 — Verificando se o cron está rodando

```bash
systemctl status cron
```

**Saída:**
```
● cron.service - Regular background program processing daemon
     Loaded: loaded (/usr/lib/systemd/system/cron.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-09 15:51:03 -03; 3min 21s ago
   Main PID: 229 (cron)
```

O cron já veio habilitado e rodando no Ubuntu. O `preset: enabled` indica que ele sobe automaticamente com o sistema — não precisa configurar nada.

---

### Passo 2 — Entendendo a sintaxe do cron

A crontab usa 5 campos de tempo seguidos do comando:

```
┌───────────── minuto      (0-59)
│ ┌─────────── hora        (0-23)
│ │ ┌───────── dia do mês  (1-31)
│ │ │ ┌─────── mês         (1-12)
│ │ │ │ ┌───── dia da semana (0=domingo, 6=sábado)
│ │ │ │ │
* * * * *  comando
```

Exemplos de expressões usadas neste exercício:

| Expressão | Significado |
|---|---|
| `* * * * *` | A cada minuto (usado no teste) |
| `0 2 * * *` | Todo dia às 02h00 (backup diário) |
| `0 5 * * 1` | Toda segunda-feira às 05h00 |
| `0 0 1 * *` | Dia 1 de cada mês à meia-noite |

---

### Passo 3 — Testando o cron com um job simples

Antes de agendar o backup, testamos que o cron estava funcionando com um job descartável.

```bash
crontab -l   # lista jobs ativos — retornou "no crontab for john"
crontab -e   # abre o editor para editar a crontab
```

Linha adicionada para teste:

```
* * * * * echo "cron funcionando em $(date)" >> /tmp/teste-cron.log
```

Após 2 minutos:

```bash
cat /tmp/teste-cron.log
```

**Saída:**
```
cron funcionando em Thu Apr  9 16:07:07 -03 2026
cron funcionando em Thu Apr  9 16:08:04 -03 2026
cron funcionando em Thu Apr  9 16:09:07 -03 2026
cron funcionando em Thu Apr  9 16:10:07 -03 2026
```

Cron executando a cada minuto e gravando no log corretamente.

---

### Passo 4 — Lendo o log do sistema

O cron registra cada execução no syslog:

```bash
grep CRON /var/log/syslog | tail -10
```

**Saída:**
```
2026-04-09T16:07:07 DESKTOP-R0N49O8 CRON[4821]: (john) CMD (echo "cron funcionando em $(date)" >> /tmp/teste-cron.log)
2026-04-09T16:08:04 DESKTOP-R0N49O8 CRON[4991]: (john) CMD (echo "cron funcionando em $(date)" >> /tmp/teste-cron.log)
2026-04-09T16:09:07 DESKTOP-R0N49O8 CRON[5671]: (john) CMD (echo "cron funcionando em $(date)" >> /tmp/teste-cron.log)
2026-04-09T16:09:07 DESKTOP-R0N49O8 CRON[5672]: (root) CMD ([ -x /usr/lib/php/sessionclean ] ...)
```

Cada linha mostra: timestamp completo com timezone, hostname, usuário que disparou o job, e o comando executado. Jobs do `root` e do `john` aparecem intercalados — o cron gerencia múltiplos usuários simultaneamente.

Após confirmar que funcionava, removemos o job de teste com `crontab -e`.

---

### Passo 5 — Criando a estrutura de teste

```bash
mkdir -p ~/backups
mkdir -p ~/dados-importantes
echo "arquivo 1" > ~/dados-importantes/config.txt
echo "arquivo 2" > ~/dados-importantes/notas.txt
ls ~/dados-importantes/
```

**Saída:**
```
config.txt  notas.txt
```

---

### Passo 6 — O script de backup rotativo

```bash
nano ~/backup-rotativo.sh
chmod 700 ~/backup-rotativo.sh
```

**Por que `chmod 700` em vez de `chmod +x`:**

O `700` dá `rwx` ao dono e nada para grupo e outros. Como o script acessa dados pessoais e roda com credenciais do usuário, não faz sentido que outros possam executá-lo. O `+x` simples adicionaria permissão de execução para todos — menos seguro.

**Conteúdo do script:**

```bash
#!/bin/bash

# backup-rotativo.sh
# Realiza backup compactado de um diretório com rotação de 7 dias

set -euo pipefail

ORIGEM="$HOME/dados-importantes"
DESTINO="$HOME/backups"
RETENCAO=7
LOG="$DESTINO/backup.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG"; }
success() { echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG"; }
error()   { echo -e "${RED}[ERRO]${NC} $1" | tee -a "$LOG"; exit 1; }

[[ ! -d "$ORIGEM" ]]  && error "Diretório de origem não encontrado: $ORIGEM"
[[ ! -d "$DESTINO" ]] && error "Diretório de destino não encontrado: $DESTINO"

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
ARQUIVO="$DESTINO/backup-$TIMESTAMP.tar.gz"

info "Iniciando backup em $(date '+%Y-%m-%d %H:%M:%S')"
info "Origem:  $ORIGEM"
info "Destino: $ARQUIVO"

tar -czf "$ARQUIVO" -C "$(dirname "$ORIGEM")" "$(basename "$ORIGEM")"
success "Backup criado: $(basename "$ARQUIVO")"

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

TOTAL=$(find "$DESTINO" -name "backup-*.tar.gz" | wc -l)
TAMANHO=$(du -sh "$ARQUIVO" | cut -f1)

echo ""
success "Backup concluído!"
info "Tamanho do arquivo: $TAMANHO"
info "Total de backups armazenados: $TOTAL"
info "Log em: $LOG"
echo ""
```

**O que cada parte faz:**

- `set -euo pipefail` — aborta o script se qualquer comando falhar, variável não definida, ou erro em pipe
- `TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')` — gera nome único por execução
- `tar -czf` — cria arquivo compactado (`c`=create, `z`=gzip, `f`=arquivo destino)
- `-C "$(dirname "$ORIGEM")"` — muda para o diretório pai antes de compactar, evitando paths absolutos dentro do `.tar.gz`
- `find -mtime +7` — localiza arquivos modificados há mais de 7 dias
- `tee -a "$LOG"` — exibe no terminal E grava no log simultaneamente

---

### Passo 7 — Testando o script

```bash
~/backup-rotativo.sh
```

**Saída:**
```
[INFO] Iniciando backup em 2026-04-09 21:59:00
[INFO] Origem:  /home/john/dados-importantes
[INFO] Destino: /home/john/backups/backup-2026-04-09_21-59-00.tar.gz
[OK] Backup criado: backup-2026-04-09_21-59-00.tar.gz
[INFO] Removendo backups com mais de 7 dias...
[INFO] Nenhum backup antigo para remover.
[OK] Backup concluído!
[INFO] Tamanho do arquivo: 4.0K
[INFO] Total de backups armazenados: 1
[INFO] Log em: /home/john/backups/backup.log
```

Verificando o conteúdo do backup:

```bash
tar -tzf ~/backups/backup-2026-04-09_21-59-00.tar.gz
```

**Saída:**
```
dados-importantes/
dados-importantes/notas.txt
dados-importantes/config.txt
```

O `tar -tzf` lista o conteúdo do arquivo compactado sem extrair — confirma que os dois arquivos estão dentro e que o path está correto (`dados-importantes/` sem path absoluto).

---

### Passo 8 — Agendando com cron

```bash
crontab -e
```

Linha adicionada:

```
0 2 * * * /home/john/backup-rotativo.sh >> /home/john/backups/cron.log 2>&1
```

**Lendo a expressão:**
- `0 2 * * *` → minuto 0, hora 2, qualquer dia/mês/dia-da-semana = **todo dia às 02h00**
- `>> /home/john/backups/cron.log` → redireciona stdout para o log (append)
- `2>&1` → redireciona stderr para o mesmo destino que stdout

O `2>&1` é essencial — sem ele, erros do script não aparecem no log e falhas silenciosas passam despercebidas.

**Confirmação:**

```bash
crontab -l
```

**Saída:**
```
0 2 * * * /home/john/backup-rotativo.sh >> /home/john/backups/cron.log 2>&1
```

---

## 💡 Conceitos aprendidos

- **`crontab -e`** — edita os agendamentos do usuário atual
- **`crontab -l`** — lista os agendamentos ativos
- **sintaxe cron** — 5 campos de tempo (`m h dom mon dow`) seguidos do comando
- **`* * * * *`** — curinga, significa "qualquer valor" para aquele campo
- **`grep CRON /var/log/syslog`** — lê o log de execuções do cron
- **`tar -czf`** — cria arquivo compactado com gzip
- **`tar -tzf`** — lista conteúdo do `.tar.gz` sem extrair
- **`find -mtime +7`** — localiza arquivos com mais de 7 dias
- **`tee -a`** — escreve no terminal e no arquivo de log simultaneamente
- **`2>&1`** — redireciona stderr para stdout (garante que erros aparecem no log)
- **`set -euo pipefail`** — modo seguro: aborta em qualquer erro

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — `crontab -1` em vez de `-l`:**
```
crontab: invalid option -- '1'
```
Causa: confundi o número `1` com a letra `l` (L minúsculo) — a fonte do terminal faz parecer idênticos.
Solução: corrigi para `crontab -l`.

**Erro 2 — Digitei o comando no prompt do editor:**
Quando o cron perguntou `Choose 1-4 [1]:` para escolher o editor, digitei `cat /tmp/teste-cron.log` em vez de `1`.
Causa: não percebi que estava no prompt de seleção do editor — achei que tinha voltado ao terminal.
Solução: rodei `crontab -e` novamente e desta vez digitei só `1` para selecionar o nano.

**Erro 3 — `/temp/` em vez de `/tmp/`:**
```
cat: /temp/teste-cron.log: No such file or directory
```
Causa: digitei `temp` mas o diretório correto é `tmp` (sem o `e`).
Solução: corrigi para `cat /tmp/teste-cron.log`.

---

## ✅ Resultado final

Sistema de backup automático configurado: o script `backup-rotativo.sh` roda todo dia às 02h00 via cron, cria um arquivo `.tar.gz` com timestamp, registra cada execução em log e remove automaticamente backups com mais de 7 dias.

---

## 📎 Arquivos relacionados

| Arquivo | Descrição |
|---|---|
| `scripts/backup-rotativo.sh` | script de backup com rotação |
| `configs/crontab.txt` | agendamentos configurados |

---

## 🔗 Referências

- `man crontab` — manual completo do crontab
- `man cron` — manual do daemon cron
- `man tar` — manual do tar
- `man find` — opções de busca por data (`-mtime`)
