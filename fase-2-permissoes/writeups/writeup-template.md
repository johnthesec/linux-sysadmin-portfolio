# [Título do exercício]

> **Fase:** Fase X — Nome da fase  
> **Tipo:** `script` | `writeup` | `desafio`  
> **Dificuldade:** Iniciante | Intermediário | Avançado  
> **Data:** AAAA-MM-DD

---

## 🎯 Objetivo

Em uma ou duas frases: o que esse exercício ensina e qual problema resolve no contexto de administração de servidores.

> Exemplo: *Aprender a localizar arquivos no sistema por nome, tamanho e data de modificação usando o comando `find`, evitando varrer pastas desnecessárias.*

---

## 🧠 Contexto

Por que um sysadmin precisa saber isso? Explique a situação real onde esse conhecimento se aplica.

> Exemplo: *Em um servidor de produção, logs podem crescer sem controle e consumir todo o disco. Saber localizar e filtrar arquivos por data ou tamanho é essencial para manutenção e troubleshooting.*

---

## ⚙️ Ambiente

| Item | Valor |
|---|---|
| Sistema operacional | Ubuntu 24.04 LTS |
| Usuário utilizado | `root` / `usuario-comum` |
| Pré-requisitos | pacote X instalado, permissão Y necessária |

---

## 📋 Passo a passo

### Passo 1 — Descrição do que foi feito

Explique o que você fez e por quê, antes de mostrar o comando.

```bash
# Comentário explicando a intenção
comando --flag argumento
```

**O que cada parte faz:**
- `comando` — ação principal
- `--flag` — explique o que essa flag muda
- `argumento` — o que está sendo passado e por quê

**Saída esperada:**
```
resultado que apareceu no terminal
```

---

### Passo 2 — Descrição do próximo passo

```bash
outro-comando --opcao valor
```

**Por que essa abordagem:**  
Explique se existe outra forma de fazer e por que você escolheu essa.

---

### Passo 3 — (repita conforme necessário)

```bash
comando-final
```

---

## 💡 Conceitos aprendidos

Liste os conceitos que esse exercício ensinou, com uma linha de explicação cada:

- **`find`** — busca arquivos no sistema com filtros por nome, tamanho, data, permissão
- **`-mtime -1`** — seleciona arquivos modificados nas últimas 24 horas
- **`2>/dev/null`** — descarta mensagens de erro para não poluir a saída
- **pipe `|`** — encadeia a saída de um comando como entrada do próximo

---

## ⚠️ Erros que cometi (e como resolvi)

Documente os erros que apareceram durante o exercício — isso é parte do aprendizado.

**Erro 1:**
```
Permission denied: /root/...
```
**Causa:** tentei acessar um diretório sem permissão de leitura.  
**Solução:** usei `sudo` ou filtrei com `2>/dev/null`.

---

## ✅ Resultado final

Descreva o que foi entregue ao final do exercício. Se for um script, mostre a versão final. Se for uma configuração, mostre o estado final do arquivo.

```bash
# Versão final do script / comando / configuração
```

---

## 📎 Arquivos relacionados

| Arquivo | Descrição |
|---|---|
| `scripts/nome-do-script.sh` | script criado neste exercício |
| `configs/nome.conf` | arquivo de configuração modificado |

---

## 🔗 Referências

- `man find` — manual completo do comando find
- [link para documentação oficial ou artigo usado]
- [outro recurso consultado]
