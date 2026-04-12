# Localização de arquivos com find, grep e pipes

> **Fase:** Fase 1 — Fundamentos do terminal
> **Tipo:** `desafio`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-12

---

## 🎯 Objetivo

Aprender a localizar arquivos no sistema por nome, extensão e data de modificação usando `find`, filtrar conteúdo com `grep` e encadear comandos com pipes — ferramentas usadas diariamente em diagnóstico e manutenção de servidores.

---

## 🧠 Contexto

Em um servidor real, você não navega em pastas manualmente procurando arquivos. Com centenas de diretórios e milhares de arquivos, o sysadmin usa `find` e `grep` para localizar o que precisa em segundos — um arquivo de configuração específico, um log com determinado erro, ou todos os arquivos modificados nas últimas 24 horas.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário utilizado | `john` |

---

## 📋 Desafios executados

### Desafio 1 — Encontrar todos os arquivos .conf em /etc

```bash
find /etc -name "*.conf" | head -10
```

**Saída:**
```
find: '/etc/ssl/private': Permission denied
/etc/ld.so.conf
/etc/logrotate.conf
/etc/ufw/ufw.conf
/etc/ufw/sysctl.conf
/etc/apport/crashdb.conf
/etc/ufw/ufw.conf
/etc/deluser.conf
/etc/ucf.conf
/etc/security/pam_env.conf
find: '/etc/cni/net.d': Permission denied
```

**O que cada parte faz:**
- `find /etc` — busca recursiva a partir de `/etc`
- `-name "*.conf"` — filtra apenas arquivos com extensão `.conf`
- `| head -10` — pipe para exibir só as 10 primeiras linhas

Os erros `Permission denied` aparecem intercalados com os resultados — o `find` continua a busca mesmo sem acesso a alguns diretórios. Para suprimir os erros:

```bash
find /etc -name "*.conf" 2>/dev/null | head -10
```

---

### Desafio 2 — Encontrar logs modificados nas últimas 24 horas

```bash
find /var/log -name "*.log" -mtime -1
```

**Saída:**
```
/var/log/kern.log
/var/log/mysql/error.log
/var/log/ufw.log
find: '/var/log/private': Permission denied
/var/log/apache2/portfolio-access.log
/var/log/unattended-upgrades/unattended-upgrades.log
/var/log/mail.log
/var/log/auth.log
```

**O que cada parte faz:**
- `-name "*.log"` — filtra arquivos com extensão `.log`
- `-mtime -1` — arquivos modificados há menos de 1 dia (24 horas)

Útil em produção para identificar quais serviços estiveram ativos recentemente.

---

### Desafio 3 — Localizar usuário no /etc/passwd com grep

```bash
grep -r "john" /etc/passwd
```

**Saída:**
```
john:x:1000:1000:,,,:/home/john:/bin/bash
```

**Lendo a linha do /etc/passwd:**
```
john  :  x   :  1000  :  1000  :  ,,,  :  /home/john  :  /bin/bash
 ↑       ↑       ↑        ↑       ↑          ↑               ↑
usuário senha  UID     GID    info      home dir          shell
        (hash  
        no shadow)
```

- `x` no campo de senha significa que a senha real está em `/etc/shadow`
- UID 1000 — primeiro usuário criado no sistema (root é 0)

---

### Desafio 4 — Listar logs disponíveis com pipe

```bash
ls /var/log/*.log | head -5
```

**Saída:**
```
/var/log/alternatives.log
/var/log/auth.log
/var/log/bootstrap.log
/var/log/dpkg.log
/var/log/fontconfig.log
```

O pipe `|` passa a saída do `ls` como entrada para o `head` — encadeamento de comandos sem criar arquivos intermediários.

---

## 💡 Conceitos aprendidos

- **`find`** — busca arquivos recursivamente por nome, extensão, data ou tamanho
- **`-name "*.conf"`** — filtra por padrão de nome com glob (`*` = qualquer coisa)
- **`-mtime -1`** — arquivos modificados nas últimas 24 horas (`-` = menos que)
- **`grep`** — filtra linhas que contêm um padrão de texto
- **`grep -r`** — busca recursiva em diretórios
- **pipe `|`** — encadeia comandos, passando a saída de um como entrada do próximo
- **`head -N`** — exibe as primeiras N linhas
- **`2>/dev/null`** — descarta mensagens de erro (stderr)
- **`/etc/passwd`** — formato: `usuario:senha:UID:GID:info:home:shell`

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — Erros de permissão intercalados na saída do find:**
```
find: '/etc/ssl/private': Permission denied
/etc/ld.so.conf
find: '/etc/cni/net.d': Permission denied
```
Causa: o `find` exibe erros de permissão no stderr junto com os resultados no stdout — a saída fica misturada.
Solução: adicionar `2>/dev/null` para separar erros dos resultados:
```bash
find /etc -name "*.conf" 2>/dev/null | head -10
```

---

## ✅ Resultado final

Localização de arquivos de configuração e logs no sistema usando `find` com filtros por nome e data, busca de padrões com `grep` e encadeamento de comandos com pipes — ferramentas essenciais para diagnóstico em servidores Linux.

---

## 🔗 Referências

- `man find` — manual completo do find com todos os filtros disponíveis
- `man grep` — manual do grep
- `man bash` — seção sobre redirecionamento e pipes
