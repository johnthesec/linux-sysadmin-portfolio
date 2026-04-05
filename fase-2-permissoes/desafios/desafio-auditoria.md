# Auditoria de permissões inseguras no Linux

> **Fase:** Fase 2 — Arquivos, Usuários & Permissões
> **Tipo:** `desafio`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-04

---

## 🎯 Objetivo

Usar o comando `find` para localizar arquivos com permissões perigosas no sistema — arquivos world-writable e arquivos com SUID — simulando uma auditoria de segurança real em servidor Linux.

---

## 🧠 Contexto

Em servidores de produção, permissões mal configuradas são uma das principais portas de entrada para invasores. Um sysadmin precisa saber identificar e corrigir dois tipos de risco:

- **Arquivos world-writable (`o+w`)** — qualquer usuário do sistema pode modificar o arquivo, incluindo scripts e configs críticas
- **Arquivos SUID** — executam com os privilégios do dono (geralmente root), podendo ser explorados para escalada de privilégios

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário utilizado | `john` |
| Pastas auditadas | `/home`, `/tmp`, `/usr/bin`, `/usr/sbin`, `/bin` |

---

## 📋 Passo a passo

### Passo 1 — Procurando arquivos world-writable

Arquivos com permissão de escrita para "outros" (`o+w`) são acessíveis por qualquer usuário do sistema.

```bash
find /home -perm -o+w -type f 2>/dev/null
```

**O que cada parte faz:**
- `find /home` — busca dentro do diretório home
- `-perm -o+w` — filtra arquivos onde "outros" têm permissão de escrita (`w`)
- `-type f` — somente arquivos (exclui diretórios)
- `2>/dev/null` — descarta erros de "Permission denied"

**Saída inicial:**
```
(vazia — nenhum arquivo inseguro encontrado)
```

---

### Passo 2 — Simulando um arquivo inseguro

Para entender o risco na prática, criamos um arquivo com permissão `777` — o pior caso possível.

```bash
touch ~/arquivo-inseguro.txt
chmod 777 ~/arquivo-inseguro.txt
ls -l ~/arquivo-inseguro.txt
```

**Saída:**
```
-rwxrwxrwx 1 john john 0 Apr 4 19:27 /home/john/arquivo-inseguro.txt
```

`777` significa que qualquer usuário pode ler, escrever e executar o arquivo — sem restrição nenhuma. Em servidor de produção, se esse fosse um script ou arquivo de configuração, qualquer usuário poderia modificá-lo.

**Auditoria detecta o arquivo:**
```bash
find /home -perm -o+w -type f 2>/dev/null
```

**Saída:**
```
/home/john/arquivo-inseguro.txt
```

---

### Passo 3 — Corrigindo a permissão insegura

```bash
chmod 600 ~/arquivo-inseguro.txt
ls -l ~/arquivo-inseguro.txt
```

**Saída:**
```
-rw------- 1 john john 0 Apr 4 19:27 /home/john/arquivo-inseguro.txt
```

`600` = só o dono pode ler e escrever. Grupo e outros não têm acesso.

**Auditoria volta limpa:**
```bash
find /home -perm -o+w -type f 2>/dev/null
# (saída vazia) ✅
```

---

### Passo 4 — Procurando arquivos SUID

O bit SUID faz o arquivo executar com os privilégios do **dono**, não de quem rodou. É necessário em alguns comandos do sistema — mas arquivos desconhecidos com SUID são um sinal de alerta.

```bash
find /usr/bin /usr/sbin /bin -perm -4000 -type f 2>/dev/null
```

**O que `-4000` significa:**
- `4000` = bit SUID ativado

**Saída:**
```
/usr/bin/passwd
/usr/bin/gpasswd
/usr/bin/umount
/usr/bin/mount
/usr/bin/sudo
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/newgrp
/usr/bin/su
/usr/bin/fusermount3
```

---

### Passo 5 — Analisando os arquivos SUID encontrados

```bash
ls -l /usr/bin/passwd
```

**Saída:**
```
-rwsr-xr-x 1 root root 64152 May 30 2024 /usr/bin/passwd
```

O `s` no lugar do `x` indica o SUID ativado:

```
-rwsr-xr-x
    ↑
    s = SUID (executa como root, não como quem chamou)
```

**Diferença entre `x` e `s`:**
- `rwx` → executa com os privilégios de quem rodou o comando
- `rws` → executa com os privilégios do **dono do arquivo** (root)

Todos os arquivos encontrados são legítimos e necessários para o funcionamento do sistema. Numa auditoria real, o sysadmin verifica se há scripts desconhecidos ou inesperados nessa lista — isso seria sinal de comprometimento do sistema.

---

### Passo 6 — Limpeza

```bash
rm ~/arquivo-inseguro.txt
```

---

## 💡 Conceitos aprendidos

- **`find -perm -o+w`** — localiza arquivos onde "outros" têm permissão de escrita
- **`find -perm -4000`** — localiza arquivos com o bit SUID ativado
- **`-type f`** — filtra apenas arquivos (exclui diretórios)
- **`2>/dev/null`** — descarta erros de permissão para não poluir a saída
- **world-writable** — arquivo acessível por qualquer usuário do sistema, risco de segurança
- **SUID (`s`)** — bit especial que faz o arquivo executar com privilégios do dono
- **auditoria de permissões** — processo de verificar e corrigir permissões inseguras no sistema

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — `find /` travou em loop no WSL:**
Rodar `find` a partir da raiz `/` no WSL varreu o disco do Windows montado em `/mnt/c`, gerando uma lista enorme e travando o terminal.
Solução: usar `Ctrl+C` para interromper e restringir o `find` a pastas específicas do Linux (`/home`, `/tmp`, `/usr/bin`).

**Erro 2 — Resultados do `/mnt/c` contaminando a auditoria:**
Os arquivos do Windows montados em `/mnt/c` apareciam como `o+w` porque o sistema de permissões do Windows é diferente.
Solução: excluir `/mnt/*` da busca com `-not -path "/mnt/*"` ou buscar diretamente nas pastas Linux relevantes.

---

## ✅ Resultado final

Aprendi a realizar uma auditoria básica de segurança no Linux — localizando arquivos com permissões perigosas, entendendo o risco de cada um e corrigindo com `chmod`. Também aprendi a identificar e interpretar arquivos SUID legítimos versus suspeitos.

---

## 📎 Arquivos relacionados

| Arquivo | Descrição |
|---|---|
| `scripts/audit-permissions.sh` | script de auditoria automatizada |
| `writeups/writeup-permissoes.md` | writeup de chmod, chown e grupos |

---

## 🔗 Referências

- `man find` — manual completo do find
- `man chmod` — manual completo do chmod
- `man stat` — exibe detalhes e permissões de arquivos
