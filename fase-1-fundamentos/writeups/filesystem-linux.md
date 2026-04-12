# Hierarquia de diretórios no Linux

> **Fase:** Fase 1 — Fundamentos do terminal
> **Tipo:** `writeup`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-12

---

## 🎯 Objetivo

Entender a hierarquia de diretórios do Linux (FHS — Filesystem Hierarchy Standard), aprender a navegar pelo sistema de arquivos e identificar onde cada tipo de arquivo fica armazenado — conhecimento essencial para qualquer sysadmin.

---

## 🧠 Contexto

Diferente do Windows, o Linux organiza tudo em uma única árvore de diretórios a partir da raiz `/`. Não existem letras de drive (C:, D:) — tudo, incluindo dispositivos e processos, é representado como arquivo ou diretório. Um sysadmin precisa saber onde estão logs, configurações, binários e dados para diagnosticar problemas e administrar o servidor.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário utilizado | `john` |

---

## 📋 Passo a passo

### Passo 1 — Explorando a raiz do sistema

```bash
ls /
```

**Saída:**
```
bin   boot  dev  etc  home  init  lib  lib64  lost+found
media mnt   opt  proc root  run   sbin snap   srv  sys  tmp  usr  var
```

**O que cada diretório principal significa:**

| Diretório | Função |
|---|---|
| `/etc` | Arquivos de configuração do sistema e serviços |
| `/home` | Diretórios pessoais dos usuários |
| `/var` | Dados variáveis — logs, cache, filas de email |
| `/bin` | Binários essenciais do sistema (`ls`, `cp`, `grep`) |
| `/usr` | Programas e bibliotecas instalados pelo usuário |
| `/tmp` | Arquivos temporários — apagados no reboot |
| `/proc` | Sistema de arquivos virtual — informações do kernel e processos |
| `/root` | Diretório home do usuário root |
| `/mnt` | Ponto de montagem para discos externos |
| `/dev` | Dispositivos de hardware representados como arquivos |

---

### Passo 2 — Explorando /etc

```bash
ls /etc | head -20
```

**Saída:**
```
NetworkManager  adduser.conf  apache2     apt
bash.bashrc     bash_completion  ca-certificates  cloud
logrotate.conf  passwd       shadow      hosts
```

O `/etc` é onde vivem todas as configurações do sistema. Arquivos críticos:

| Arquivo | O que contém |
|---|---|
| `/etc/passwd` | Lista de usuários do sistema |
| `/etc/shadow` | Senhas criptografadas (só root acessa) |
| `/etc/hosts` | Mapeamento estático de IPs e hostnames |
| `/etc/bash.bashrc` | Configuração global do bash |
| `/etc/apache2/` | Configuração do servidor web Apache |

---

### Passo 3 — Explorando /var

```bash
ls /var
```

**Saída:**
```
backups  cache  crash  lib  local  lock  log  mail  opt  run  snap  spool  tmp  www
```

O `/var` guarda dados que mudam constantemente durante a operação do sistema:

| Subdiretório | O que contém |
|---|---|
| `/var/log` | Logs do sistema e serviços |
| `/var/www` | Arquivos dos sites (nginx, apache) |
| `/var/cache` | Cache de pacotes e aplicações |
| `/var/backups` | Backups automáticos do sistema |
| `/var/lib` | Dados persistentes de aplicações |

---

### Passo 4 — Explorando /var/log

```bash
ls /var/log | head -10
```

**Saída:**
```
README  alternatives.log  apache2  apt  auth.log
auth.log.1  auth.log.2.gz  bootstrap.log  btmp  dist-upgrade
```

Logs mais importantes para um sysadmin:

| Arquivo | O que registra |
|---|---|
| `auth.log` | Tentativas de login e autenticação |
| `syslog` | Mensagens gerais do sistema |
| `apache2/` | Acessos e erros do servidor web |
| `ufw.log` | Conexões bloqueadas pelo firewall |
| `mysql/error.log` | Erros do banco de dados |

---

### Passo 5 — Verificando espaço em disco

```bash
df -h /
```

**Saída:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G  6.8G  949G   1% Use% /
```

O `df -h` mostra o uso do disco de forma legível (`-h` = human readable). Em produção, monitorar essa métrica é essencial — disco cheio derruba serviços.

---

### Passo 6 — Verificando tamanho de diretório

```bash
du -sh /etc
```

**Saída:**
```
du: cannot read directory '/etc/ssl/private': Permission denied
du: cannot read directory '/etc/cni/net.d': Permission denied
6.5M    /etc
```

Os erros `Permission denied` são esperados — alguns subdiretórios do `/etc` são restritos ao root. O tamanho total (`6.5M`) ainda é calculado para os diretórios acessíveis. Para suprimir os erros:

```bash
du -sh /etc 2>/dev/null
```

O `2>/dev/null` redireciona o stderr (canal 2) para o `/dev/null` — descarta mensagens de erro sem afetar a saída principal.

---

## 💡 Conceitos aprendidos

- **FHS** — Filesystem Hierarchy Standard, padrão de organização de diretórios no Linux
- **`ls /`** — lista o conteúdo da raiz do sistema
- **`/etc`** — configurações; **`/var`** — dados variáveis; **`/home`** — usuários; **`/tmp`** — temporários
- **`df -h`** — uso de disco por partição em formato legível
- **`du -sh`** — tamanho de um diretório específico
- **`2>/dev/null`** — descarta mensagens de erro (redireciona stderr para o nulo)
- **`head -N`** — exibe apenas as primeiras N linhas da saída

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — Permission denied no du:**
```
du: cannot read directory '/etc/ssl/private': Permission denied
```
Causa: alguns subdiretórios do `/etc` são restritos ao root — o usuário `john` não tem permissão de leitura.
Solução: usar `2>/dev/null` para suprimir os erros, ou rodar com `sudo` quando necessário.

---

## ✅ Resultado final

Mapeamento completo da hierarquia de diretórios do Linux — onde ficam configurações, logs, binários e dados de usuário. Base essencial para administrar qualquer servidor Linux.

---

## 🔗 Referências

- `man hier` — manual da hierarquia de diretórios do Linux
- `man df` — manual do df
- `man du` — manual do du
