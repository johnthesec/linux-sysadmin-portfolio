# Permissões e controle de acesso no Linux

> **Fase:** Fase 2 — Arquivos, Usuários & Permissões
> **Tipo:** `writeup`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-04

---

## 🎯 Objetivo

Entender como o Linux controla o acesso a arquivos e diretórios, aprender a ler e modificar permissões com `chmod` e `chown`, gerenciar grupos de usuários e revogar acessos — simulando situações reais de administração de servidores.

---

## 🧠 Contexto

Em um servidor, múltiplos usuários e serviços coexistem. Um sysadmin precisa garantir que cada usuário acesse apenas o que deve — nem mais, nem menos. Permissões mal configuradas são uma das causas mais comuns de falhas de segurança em servidores Linux.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário principal | `john` |
| Usuário de teste | `teste-user` |
| Grupo criado | `sysadmins` |

---

## 📋 Passo a passo

### Passo 1 — Lendo permissões com `ls -l`

Antes de modificar qualquer coisa, é preciso saber ler as permissões existentes.

```bash
ls -l /etc/passwd /etc/shadow /etc/hosts
```

**Saída:**
```
-rw-r--r-- 1 root root   1734 jan 10 08:00 /etc/hosts
-rw-r--r-- 1 root root   2847 jan 10 08:00 /etc/passwd
-rw-r----- 1 root shadow  890 jan 10 08:00 /etc/shadow
```

**Como ler a linha de permissões:**
```
-  rw-  r--  r--
↑   ↑    ↑    ↑
│  dono grupo outros
tipo (- = arquivo, d = diretório)
```

**O que cada letra significa:**
- `r` (read) = pode ler
- `w` (write) = pode escrever/modificar
- `x` (execute) = pode executar
- `-` = sem permissão

O `/etc/shadow` é mais restrito que o `/etc/passwd` porque guarda senhas criptografadas de todos os usuários. Se qualquer pessoa pudesse ler, poderia tentar quebrar as senhas offline.

---

### Passo 2 — Entendendo a notação octal com `stat`

```bash
stat /etc/passwd
stat /etc/shadow
```

**Saída relevante:**
```
/etc/passwd  → Access: (0644/-rw-r--r--)
/etc/shadow  → Access: (0640/-rw-r-----)
```

**Como converter letras para números:**

| Permissão | Valor |
|---|---|
| `r` | 4 |
| `w` | 2 |
| `x` | 1 |
| `-` | 0 |

Cada bloco é a soma dos valores:
- `rw-` = 4+2+0 = **6**
- `r--` = 4+0+0 = **4**
- `---` = 0+0+0 = **0**

| Arquivo | Octal | Dono | Grupo | Outros |
|---|---|---|---|---|
| `/etc/passwd` | `0644` | `rw-` | `r--` | `r--` |
| `/etc/shadow` | `0640` | `rw-` | `r--` | `---` |

A diferença: outros usuários não podem nem ler o `/etc/shadow`.

---

### Passo 3 — Aplicando permissões com `chmod`

```bash
# Cria arquivo de teste
touch ~/teste-permissoes.txt
ls -l ~/teste-permissoes.txt
```

**Saída:**
```
-rw-r--r-- 1 john john 0 Apr 4 14:39 /home/john/teste-permissoes.txt
```

Padrão do Linux para arquivos novos: `0644`.

**Tornando o arquivo privado (só o dono acessa):**

```bash
chmod 600 ~/teste-permissoes.txt
```

- dono → `rw-` = 6
- grupo → `---` = 0
- outros → `---` = 0

---

### Passo 4 — Scripts precisam de permissão de execução

```bash
echo '#!/bin/bash
echo "Script rodando!"' > ~/meu-script.sh

# Tentativa sem permissão de execução
~/meu-script.sh
```

**Saída:**
```
bash: /home/john/meu-script.sh: Permission denied
```

**Solução:**
```bash
chmod 700 ~/meu-script.sh
~/meu-script.sh
```

**Saída:**
```
Script rodando!
```

`700` = dono tem `rwx`, grupo e outros têm `---`.

---

### Passo 5 — Mudando o dono com `chown`

```bash
sudo chown teste-user ~/meu-script.sh
ls -l ~/meu-script.sh
```

**Saída:**
```
-rwx------ 1 teste-user john 35 Apr 4 14:51 /home/john/meu-script.sh
```

O `john` agora é o grupo — mas o bloco de grupo é `---`, então perde o acesso:

```bash
~/meu-script.sh
# bash: /home/john/meu-script.sh: Permission denied
```

---

### Passo 6 — Gerenciando grupos de acesso

Cenário: `john` e `teste-user` precisam compartilhar o script, mas outros não podem ver.

```bash
# Cria o grupo
sudo groupadd sysadmins

# Adiciona os dois usuários
sudo usermod -aG sysadmins john
sudo usermod -aG sysadmins teste-user

# Confirma
getent group sysadmins
# sysadmins:x:1002:john,teste-user
```

**Aplicando as permissões corretas:**

```bash
sudo chown john:sysadmins ~/meu-script.sh
chmod 750 ~/meu-script.sh
ls -l ~/meu-script.sh
```

**Saída:**
```
-rwxr-x--- 1 john sysadmins 35 Apr 4 14:51 /home/john/meu-script.sh
```

`750` = dono `rwx`, grupo `r-x`, outros `---`.

---

### Passo 7 — Permissão é uma cadeia: diretório + arquivo

Mesmo com o arquivo liberado, o `teste-user` recebia `Permission denied`. O problema estava no diretório:

```bash
ls -ld /home/john
# drwxr-x--- 14 john john 4096 Apr 4 14:51 /home/john
```

O grupo do diretório era `john` — e o `teste-user` não estava nele, caindo em "outros" (`---`). Não conseguia nem entrar na pasta.

**Solução:**
```bash
sudo chown john:sysadmins /home/john
sudo -u teste-user ~/meu-script.sh
# Script rodando! ✅
```

**Conclusão:** para acessar um arquivo, o usuário precisa de permissão em **toda a cadeia de diretórios** até ele.

---

### Passo 8 — Revogando acesso

```bash
# Remove do grupo
sudo gpasswd -d teste-user sysadmins

# Devolve diretório e arquivo para john
sudo chown john:john /home/john
sudo chown john:john ~/meu-script.sh

# Testa que o acesso foi revogado
sudo -u teste-user ~/meu-script.sh
# sudo: unable to execute: Permission denied ✅
```

---

### Passo 9 — Limpeza do ambiente

```bash
rm ~/meu-script.sh
rm ~/teste-permissoes.txt
sudo userdel -r teste-user
sudo groupdel sysadmins

# Confirmação
getent passwd teste-user   # vazio
getent group sysadmins     # vazio
```

> O aviso `mail spool not found` do `userdel` é normal — apenas informa que não havia caixa de email para o usuário.

---

## 💡 Conceitos aprendidos

- **`ls -l`** — exibe permissões, dono e grupo de arquivos e diretórios
- **`stat`** — exibe permissões em notação octal e detalhes do arquivo
- **notação octal** — `r=4, w=2, x=1`, somados por bloco (dono/grupo/outros)
- **`chmod`** — altera as permissões de um arquivo ou diretório
- **`chown dono:grupo`** — altera dono e grupo de um arquivo
- **`groupadd`** — cria um novo grupo no sistema
- **`usermod -aG`** — adiciona um usuário a um grupo sem remover dos outros
- **`gpasswd -d`** — remove um usuário de um grupo
- **`userdel -r`** — remove usuário e seu diretório home
- **`getent`** — consulta informações de usuários e grupos
- **cadeia de permissões** — acesso a um arquivo depende das permissões de todos os diretórios pai

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — Case-sensitive no path:**
```
cat: /home/John/meu-script.sh: No such file or directory
```
Causa: usei `John` com J maiúsculo. Linux diferencia maiúsculas de minúsculas em caminhos.
Solução: corrigi para `/home/john/meu-script.sh`.

**Erro 2 — Notação octal invertida:**
Calculei `chmod 401` quando queria `dono=rwx, grupo=r-x, outros=---`.
Causa: confundi a ordem dos blocos.
Solução: lembrar que a ordem é sempre `dono → grupo → outros`, e recalculei: `7-5-0 = 750`.

**Erro 3 — Permission denied mesmo com arquivo liberado:**
O arquivo tinha as permissões certas, mas o `teste-user` ainda recebia `Permission denied`.
Causa: o diretório `/home/john` não permitia entrada para o grupo `sysadmins`.
Solução: aplicar `chown john:sysadmins` também no diretório.

---

## ✅ Resultado final

Aprendi a controlar acesso a arquivos e diretórios no Linux de forma precisa — concedendo, compartilhando e revogando permissões como um sysadmin faria em um servidor real.

---

## 🔗 Referências

- `man chmod` — manual completo do chmod
- `man chown` — manual completo do chown
- `man usermod` — opções de gerenciamento de usuários
- `man groupadd` / `man gpasswd` — gerenciamento de grupos
