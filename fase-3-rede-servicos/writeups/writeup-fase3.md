# Servidor web, systemd e firewall no Linux

> **Fase:** Fase 3 — Rede, Serviços & Processos
> **Tipo:** `writeup`
> **Dificuldade:** Iniciante
> **Data:** 2026-04-06

---

## 🎯 Objetivo

Subir um servidor web nginx, aprender a controlar serviços com systemd e configurar um firewall com boas práticas de segurança — simulando o setup inicial de um servidor real.

---

## 🧠 Contexto

Todo servidor Linux em produção tem pelo menos três camadas que um sysadmin precisa dominar: um servidor web para servir conteúdo, o systemd para gerenciar os serviços e um firewall para controlar quem pode acessar o quê. Configurar essas três camadas corretamente é o ponto de partida para qualquer servidor seguro.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Usuário utilizado | `john` |
| Serviços configurados | `nginx`, `apache2` (desabilitado) |
| Firewall | `ufw` |

---

## 📋 Passo a passo

### Passo 1 — Verificando o nginx

Antes de instalar qualquer coisa, verificamos se o nginx já estava presente:

```bash
which nginx
systemctl status nginx
```

**Saída:**
```
/usr/sbin/nginx

● nginx.service - A high performance web server
     Active: active (running) since Mon 2026-04-06 10:10:07
     Main PID: 274 (nginx)
     ├─274 nginx: master process
     └─275..293 nginx: worker process (x12)
```

O nginx usa modelo **master + workers**: o processo master gerencia, os workers atendem as conexões. Isso garante que uma conexão travada não derruba o servidor inteiro.

---

### Passo 2 — Diagnosticando conflito de porta

Ao rodar `curl http://localhost`, a página retornada era do **Apache2**, não do nginx:

```bash
curl http://localhost
# Apache2 Default Page: It works!
```

Investigamos quem estava ocupando a porta 80:

```bash
sudo ss -tlnp | grep :80
```

**Saída:**
```
LISTEN 0 511 0.0.0.0:80  users:(("nginx",pid=274...))
```

O nginx estava na porta 80 — mas servindo o arquivo `index.html` deixado pelo Apache2 em `/var/www/html/`. Os dois compartilham a mesma pasta de arquivos.

Confirmamos que o Apache2 havia falhado ao tentar subir:

```bash
systemctl status apache2
```

**Saída:**
```
Active: failed
(98)Address already in use: AH00072
no listening sockets available
```

O nginx subiu primeiro e tomou a porta 80. O Apache2 tentou subir depois e falhou porque a porta já estava ocupada. **Dois servidores não podem escutar na mesma porta.**

---

### Passo 3 — Criando uma página customizada

Substituímos a página padrão pela nossa:

```bash
sudo nano /var/www/html/index.html
```

O `sudo` é necessário porque o arquivo pertence ao `root`:

```
-rw-r--r-- 1 root root 10671 /var/www/html/index.html
                 ↑
            john cai em "outros" → só leitura
```

**Conteúdo da página:**

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Linux SysAdmin Portfolio</title>
</head>
<body>
  <h1>Servidor nginx funcionando!</h1>
  <p>Configurado por john — Linux SysAdmin em formação.</p>
  <p>Fase 3 — Rede, Serviços e Processos</p>
</body>
</html>
```

**Confirmação:**

```bash
curl http://localhost
# <h1>Servidor nginx funcionando!</h1>
```

---

### Passo 4 — Controlando serviços com systemctl

Os quatro comandos principais do systemd:

```bash
sudo systemctl stop nginx      # para agora
sudo systemctl start nginx     # sobe agora
sudo systemctl reload nginx    # recarrega config sem derrubar
sudo systemctl restart nginx   # para e sobe de novo (stop + start)
```

**Diferença entre reload e restart:**

| Comando | O que faz | Quando usar |
|---|---|---|
| `reload` | Recarrega configs, mantém conexões ativas | Após editar nginx.conf |
| `restart` | Mata tudo e sobe do zero | Quando o serviço travou |

Em produção, sempre preferir `reload` — não interrompe quem está conectado.

**Controlando inicialização automática:**

```bash
sudo systemctl enable nginx    # inicia com o sistema
sudo systemctl disable nginx   # não inicia mais com o sistema
```

Diferença importante:
```
stop    → para agora, volta no próximo boot
disable → impede inicialização automática (não afeta o que roda agora)
```

Para liberar RAM de vez — usar os dois juntos:

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
```

---

### Passo 5 — Firewall com ufw

Cada serviço escuta em uma porta específica:

```
80  → HTTP  (nginx, apache)
443 → HTTPS (nginx com SSL)
22  → SSH   (acesso remoto)
3306→ MySQL (banco de dados)
```

Sem firewall, todas as portas ficam abertas para qualquer conexão.

**Configuração inicial (insegura):**

```bash
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 22/tcp   # SSH aberto para qualquer IP
sudo ufw enable
```

**Problema:** SSH com `Anywhere` significa que qualquer IP no mundo pode tentar se conectar — bots ficam testando senhas constantemente.

**Configuração correta com boas práticas:**

```bash
# Política padrão — bloqueia tudo que não for explicitamente permitido
sudo ufw default deny incoming
sudo ufw default allow outgoing

# HTTP público (servidor web é para todo mundo)
sudo ufw allow 80/tcp

# SSH restrito ao IP local
sudo ufw allow from 172.27.102.24 to any port 22
```

**Resultado final:**

```bash
sudo ufw status numbered
```

```
Status: active
[ 1] 80/tcp   ALLOW IN  Anywhere        ← HTTP público
[ 2] 22       ALLOW IN  172.27.102.24   ← SSH só do IP local
[ 3] 80/tcp   ALLOW IN  Anywhere (v6)   ← HTTP IPv6
```

---

### Passo 6 — Script de health check

Script para verificar rapidamente o estado do servidor:

```bash
chmod +x ~/health-check.sh
~/health-check.sh
```

**Saída:**
```
================================
   HEALTH CHECK — 2026-04-06 16:16
================================

[INFO] RAM disponível: 6317MB
[OK]   Disco em 1% de uso
[INFO] Status dos serviços:
[OK]   nginx está rodando
[FALHA] ssh está parado!
================================
```

O SSH parado é esperado no WSL — num servidor real na nuvem estaria rodando.

---

### Passo 7 — Limpeza e liberação de RAM

Para não consumir RAM em background:

```bash
sudo systemctl stop nginx && sudo systemctl disable nginx
sudo systemctl stop apache2 && sudo systemctl disable apache2

systemctl is-active nginx    # inactive
systemctl is-active apache2  # failed
systemctl is-enabled nginx   # disabled
systemctl is-enabled apache2 # disabled
```

---

## 💡 Conceitos aprendidos

- **`systemctl status`** — lê o estado de um serviço com log de eventos
- **`ss -tlnp`** — mostra quais processos estão escutando em quais portas
- **modelo master/worker** — nginx usa um processo master + vários workers
- **conflito de porta** — dois serviços não podem escutar na mesma porta
- **`reload` vs `restart`** — reload mantém conexões, restart recria tudo
- **`enable` vs `disable`** — controla se o serviço sobe com o sistema
- **`ufw default deny incoming`** — bloqueia tudo que não for explicitamente permitido
- **SSH restrito por IP** — evita ataques de força bruta na porta 22
- **porta** — canal de comunicação identificado por número, cada serviço tem o seu

---

## ⚠️ Erros que cometi (e como resolvi)

**Erro 1 — Typo no protocolo do curl:**
```
curl htt://localhost
curl: (1) Protocol "htt" not supported
```
Causa: digitei `htt` em vez de `http`.
Solução: corrigi para `curl http://localhost`.

**Erro 2 — Typo no comando systemctl:**
```
system status nginx
Command 'system' not found
```
Causa: esqueci o `ctl` no final.
Solução: corrigi para `systemctl status nginx`.

**Erro 3 — Deletei a regra errada no ufw:**
Tentei deletar a regra `[4]` mas ela não existia. Acabei deletando a regra `[2]` que era o HTTP (80) em vez do SSH (22).
Causa: os números das regras mudam quando você deleta uma — e não conferi o `status numbered` antes.
Solução: recriei todas as regras do zero com `ufw delete` e depois adicionei na ordem correta.

**Erro 4 — SSH aberto para Anywhere:**
Configurei `ufw allow 22/tcp` inicialmente, deixando SSH acessível para qualquer IP.
Causa: não pensei nas implicações de segurança.
Solução: removi a regra e substituí por `ufw allow from 172.27.102.24 to any port 22`.

---

## ✅ Resultado final

Servidor nginx configurado com página customizada, serviços controlados via systemd e firewall com boas práticas de segurança — SSH restrito por IP e política padrão de deny incoming.

---

## 📎 Arquivos relacionados

| Arquivo | Descrição |
|---|---|
| `scripts/health-check.sh` | monitor de saúde do servidor |
| `configs/nginx.conf` | configuração comentada do nginx |

---

## 🔗 Referências

- `man systemctl` — manual completo do systemctl
- `man ufw` — manual completo do ufw
- `man nginx` — manual do nginx
- `man ss` — manual do ss (substituiu o netstat)
