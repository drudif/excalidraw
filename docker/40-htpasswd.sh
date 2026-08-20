#!/bin/sh
# Gera o arquivo de senha do nginx no boot, a partir da variavel de ambiente.
#
# Roda via /docker-entrypoint.d/ da imagem oficial do nginx, que executa os
# scripts com `set -e` antes de subir o servidor. Entao sair com erro aqui
# derruba o container de proposito: e melhor o site cair de forma barulhenta
# do que subir aberto em silencio.

set -e

if [ -z "$APP_PASSWORD" ]; then
    echo "ERRO: variavel APP_PASSWORD nao definida." >&2
    echo "      Defina no Railway antes de subir, senao a instancia ficaria publica." >&2
    exit 1
fi

APP_USER="${APP_USER:-excalidraw}"

# -i le a senha da stdin em vez de argv, pra ela nao aparecer em `ps`.
printf '%s' "$APP_PASSWORD" | htpasswd -i -c -m /etc/nginx/.htpasswd "$APP_USER"
chmod 644 /etc/nginx/.htpasswd

echo "senha de acesso configurada para o usuario '$APP_USER'"

# Diagnostico: quais arquivos de config o nginx realmente le, e se a diretiva
# de senha entrou na config efetiva.
echo "--- arquivos de config carregados pelo nginx ---"
nginx -T 2>&1 | grep -E "^# configuration file" || echo "  (nginx -T falhou)"
echo "--- diretivas de auth na config efetiva ---"
nginx -T 2>&1 | grep -E "auth_basic|listen |server_name" || echo "  NENHUMA diretiva auth_basic encontrada"
