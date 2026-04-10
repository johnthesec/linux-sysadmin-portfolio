# app.py — aplicação WSGI mínima para validar o stack
# Fase 4 — Linux SysAdmin Portfolio

def application(environ, start_response):
    status = '200 OK'
    headers = [('Content-Type', 'text/html; charset=utf-8')]
    start_response(status, headers)

    body = """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <title>Stack Python funcionando</title>
    </head>
    <body>
        <h1>Stack Apache + Python funcionando!</h1>
        <p>Servidor configurado por john — Linux SysAdmin em formação.</p>
        <p>Fase 4 — Automação e Projeto Final</p>
    </body>
    </html>
    """
    return [body.encode('utf-8')]
