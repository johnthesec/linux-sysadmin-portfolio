# Hardening de SSH no Linux

> **Fase:** Fase 3 — Rede, Serviços & Processos
> **Tipo:** `desafio`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-08

---

## 🎯 Objetivo

Instalar e configurar o servidor SSH com boas práticas de segurança — desabilitando login por senha, bloqueando acesso root e usando autenticação por chave criptográfica — simulando o hardening feito em servidores reais antes de ir para produção.

---

## 🧠 Contexto

SSH é a porta de entrada de qualquer servidor Linux remoto. Com a configuração padrão, qualquer pessoa no mundo pode tentar se conectar usando senha — bots ficam 24h testando combinações de usuário e senha (ataque de força bruta). O hardening elimina esse vetor de ataque ao substituir senhas por chaves criptográficas e restringir quem pode conectar.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário utilizado | `john` |
| Pacote instalado | `openssh-server` |
| Tipo de chave | ED25519 |

---

## 📋 Passo a passo

### Passo 1 — Instalando o servidor SSH

```bash
sudo apt install openssh-server -y
```

O apt instalou o servidor e criou automaticamente três pares de chaves do servidor:

```
RSA key    → compatível com sistemas mais antigos
ECDSA key  → mais moderna e eficiente
ED25519    → a mais segura — recomendada atualmente
```

---

### Passo 2 — Verificando o estado inicial

```bash
systemctl status ssh
grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"
```

**Saída do status:**
```
Active: inactive (dead)
TriggeredBy: ● ssh.socket
```

**Configuração padrão:**
```
Include /etc/ssh/sshd_config.d/*.conf
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
```

A configuração padrão não tem `PasswordAuthentication` explícito — o que significa que está habilitado por padrão. Qualquer usuário pode tentar login com senha.

---

### Passo 3 — Gerando o par de chaves ED25519

```bash
ssh-keygen -t ed25519 -C "portfolio-sysadmin"
```

**O que cada parte faz:**
- `ssh-keygen` — gera o par de chaves
- `-t ed25519` — tipo da chave (ED25519 é o mais seguro atualmente)
- `-C "portfolio-sysadmin"` — comentário para identificar a chave

O par já existia em `~/.ssh/`:

```bash
ls -l ~/.ssh/
```

**Saída:**
```
-rw------- 1 john john 419 Apr  5 11:03 id_ed25519      ← chave privada
-rw-r--r-- 1 john john 105 Apr  5 11:03 id_ed25519.pub  ← chave pública
-rw------- 1 john john 978 Apr  5 11:12 known_hosts
```

As permissões já estavam corretas:
- `600` na chave privada — só o dono lê. Se estiver mais aberta, o SSH recusa a chave por segurança
- `644` na chave pública — pode ser compartilhada

---

### Passo 4 — Autorizando a chave para login

```bash
# Copia a chave pública para o arquivo de chaves autorizadas
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# Permissão correta no arquivo
chmod 600 ~/.ssh/authorized_keys

# Confirma o conteúdo
cat ~/.ssh/authorized_keys
```

**Saída:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... portfolio-sysadmin
```

O `authorized_keys` é o arquivo que o servidor SSH consulta para verificar se a chave do cliente está autorizada a conectar.

---

### Passo 5 — Aplicando o hardening no sshd_config

```bash
sudo nano /etc/ssh/sshd_config
```

Linhas adicionadas no final do arquivo:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

**O que cada diretiva faz:**

| Diretiva | Valor | Motivo |
|---|---|---|
| `PermitRootLogin` | `no` | root não pode logar direto — invasor teria que comprometer um usuário comum primeiro |
| `PasswordAuthentication` | `no` | elimina ataques de força bruta — sem senha, sem tentativas |
| `PubkeyAuthentication` | `yes` | habilita autenticação por chave |
| `AuthorizedKeysFile` | `.ssh/authorized_keys` | define onde o servidor busca as chaves autorizadas |

---

### Passo 6 — Validando e aplicando a configuração

```bash
# Cria diretório necessário no WSL
sudo mkdir -p /run/sshd

# Testa se a configuração está válida (sem reiniciar)
sudo sshd -t

# Inicia o servidor
sudo systemctl start ssh

# Reinicia para aplicar as novas configs
sudo systemctl restart ssh

# Confirma que está rodando
systemctl is-active ssh
```

**Saída:**
```
active
```

O `sshd -t` é essencial antes de reiniciar em produção — um erro no `sshd_config` pode travar o SSH e te deixar sem acesso ao servidor.

---

### Passo 7 — Testando a conexão por chave

```bash
ssh -i ~/.ssh/id_ed25519 john@localhost
```

**Saída:**
```
The authenticity of host 'localhost (127.0.0.1)' can't be established.
ED25519 key fingerprint is SHA256:u+HB4IwAe5F6t4gQLPNVDdWnVygrlOxRqG+EHZWbUaM.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)
```

Conectado sem digitar senha — a chave fez tudo automaticamente. ✅

O aviso na primeira conexão é normal — o SSH pergunta se você confia no servidor. Após confirmar, adiciona ao `known_hosts` e nas próximas conexões não pergunta mais.

---

## 💡 Conceitos aprendidos

- **ED25519** — algoritmo de chave assimétrica mais seguro e recomendado atualmente para SSH
- **chave privada / pública** — a pública fica no servidor, a privada fica só com você
- **`authorized_keys`** — arquivo que lista quais chaves públicas têm permissão de login
- **`PermitRootLogin no`** — impede login direto como root via SSH
- **`PasswordAuthentication no`** — elimina ataques de força bruta
- **`sshd -t`** — valida a configuração sem reiniciar o serviço
- **`known_hosts`** — lista de servidores conhecidos e verificados
- **fingerprint** — impressão digital do servidor, usada para verificar autenticidade na primeira conexão

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — Missing privilege separation directory:**
```
Missing privilege separation directory: /run/sshd
```
Causa: no WSL o diretório `/run/sshd` não existe por padrão.
Solução: criar manualmente com `sudo mkdir -p /run/sshd` antes de testar a configuração.

---

## ✅ Resultado final

Servidor SSH configurado com hardening completo — autenticação exclusiva por chave ED25519, login root bloqueado e senha desabilitada. Conexão testada e funcionando sem senha.

**Antes do hardening:**
```
PasswordAuthentication → habilitado (qualquer um pode tentar senha)
PermitRootLogin        → habilitado (root exposto a ataques)
```

**Depois do hardening:**
```
PasswordAuthentication no  → força bruta eliminado
PermitRootLogin no         → root protegido
PubkeyAuthentication yes   → só chave autorizada entra
```

---

## 📎 Arquivos relacionados

| Arquivo | Descrição |
|---|---|
| `scripts/health-check.sh` | monitor de saúde — verifica se SSH está rodando |
| `writeups/writeup-fase3.md` | writeup de nginx, systemd e ufw |

---

## 🔗 Referências

- `man sshd_config` — manual completo das diretivas de configuração
- `man ssh-keygen` — manual de geração de chaves
- `man ssh` — manual do cliente SSH
