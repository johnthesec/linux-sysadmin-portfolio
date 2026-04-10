# Projeto Final — Stack Apache + MySQL + Python

> **Fase:** Fase 4 — Automação & Projeto Final
> **Tipo:** projeto integrador
> **Dificuldade:** Intermediário
> **Data:** 2026-04-10

---

## 🎯 Objetivo

Instalar e configurar um stack completo de servidor web — Apache + MySQL + Python via mod_wsgi — simulando o setup inicial de um servidor de aplicação real, com script de instalação automatizada e configuração documentada.

---

## 🧠 Contexto

Todo servidor de aplicação em produção tem três camadas: um servidor web para receber requisições (Apache), um banco de dados para persistir dados (MySQL) e uma linguagem de back-end para processar a lógica (Python). Configurar essas três camadas corretamente e de forma reproduzível — usando um script de instalação — é uma habilidade central de um sysadmin.

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS (WSL) |
| Servidor web | Apache 2.4.58 |
| Banco de dados | MySQL 8.0.45 |
| Linguagem | Python 3.12.3 |
| Módulo WSGI | libapache2-mod-wsgi-py3 5.0.0 |
| Diretório do projeto | `/var/www/portfolio` |

---

## 📁 Estrutura

```
lamp-setup/
├── install.sh       ← instalação automatizada do stack completo
├── vhost.conf       ← Virtual Host Apache comentado
├── app.py           ← aplicação Python mínima (WSGI)
└── README.md        ← este arquivo
```

---

## 🚀 Instalação rápida

```bash
chmod +x install.sh
sudo ./install.sh
```

O script verifica o que já está instalado e instala apenas o que falta — pode ser rodado em um servidor limpo ou em um ambiente parcialmente configurado.

---

## 📋 O que o script faz

1. **Verifica e instala dependências** — `apache2`, `mysql-server`, `python3`, `libapache2-mod-wsgi-py3`
2. **Cria o diretório do projeto** — `/var/www/portfolio` com as permissões corretas
3. **Cria a aplicação Python** — `app.py` com uma resposta HTTP mínima via WSGI
4. **Configura o Virtual Host** — ativa `portfolio.conf` e desativa o site padrão
5. **Inicia os serviços** — Apache e MySQL habilitados no boot
6. **Valida a instalação** — testa se o Apache responde e se o MySQL está ativo

---

## 🗄️ Configuração do MySQL

Após rodar o `install.sh`, configure o banco de dados manualmente:

```bash
sudo mysql
```

```sql
-- Banco de dados dedicado ao projeto
CREATE DATABASE portfolio_db;

-- Usuário com senha forte (política do MySQL 8 exige maiúscula + número + símbolo)
CREATE USER 'portfolio_user'@'localhost' IDENTIFIED BY 'SuaSenha@2026';

-- Privilégios apenas no banco do projeto — nunca usar GRANT ALL em *.*
GRANT ALL PRIVILEGES ON portfolio_db.* TO 'portfolio_user'@'localhost';
FLUSH PRIVILEGES;

-- Confirma
SELECT user, host FROM mysql.user WHERE user = 'portfolio_user';
EXIT;
```

**Validação:**

```bash
mysql -u portfolio_user -p'SuaSenha@2026' -e "SHOW DATABASES;"
```

Saída esperada — `portfolio_user` vê apenas os bancos que tem acesso:
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| performance_schema |
| portfolio_db       |
+--------------------+
```

---

## 🌐 Como funciona o mod_wsgi

O `mod_wsgi` é o módulo que permite o Apache executar aplicações Python diretamente, sem precisar de um servidor intermediário.

```
Navegador
    │
    ▼
Apache (porta 80)
    │  WSGIScriptAlias / /var/www/portfolio/app.py
    ▼
mod_wsgi
    │
    ▼
app.py → função application(environ, start_response)
    │
    ▼
Resposta HTTP para o navegador
```

A função `application` é o ponto de entrada obrigatório do padrão WSGI — o Apache chama essa função para cada requisição.

---

## 🔧 Comandos úteis

```bash
# Verificar status dos serviços
systemctl status apache2
systemctl status mysql

# Testar configuração do Apache sem reiniciar
sudo apache2ctl configtest

# Aplicar mudanças no Virtual Host
sudo systemctl reload apache2

# Ver logs em tempo real
sudo tail -f /var/log/apache2/portfolio-error.log
sudo tail -f /var/log/apache2/portfolio-access.log

# Acessar MySQL como root
sudo mysql

# Acessar MySQL como portfolio_user
mysql -u portfolio_user -p portfolio_db
```

---

## ⚠️ Erros encontrados durante o setup

**Erro 1 — Política de senha do MySQL 8:**
```
ERROR 1819 (HY000): Your password does not satisfy the current policy requirements
```
Causa: o MySQL 8 tem validação de senha ativa por padrão — exige maiúscula, número e símbolo.
Solução: usar senha complexa como `Portfolio@2026` em vez de `senha123`.

**Erro 2 — GRANT falhou em cascata:**
```
ERROR 1410 (42000): You are not allowed to create a user with GRANT
```
Causa: o `GRANT` tentou criar o usuário implicitamente, mas falhou porque a política de senha bloqueou o `CREATE USER` anterior.
Solução: corrigir o `CREATE USER` com senha válida primeiro — o `GRANT` subsequente funcionou normalmente.

---

## 🔗 Referências

- `man apache2` — manual do Apache
- `man mysql` — manual do cliente MySQL
- [mod_wsgi documentation](https://modwsgi.readthedocs.io/)
- `man a2ensite` / `man a2dissite` — ativação de Virtual Hosts
