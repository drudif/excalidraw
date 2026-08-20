#!/bin/sh
# Gera o arquivo de senha do nginx no boot, a partir da variavel de ambiente.
#
# Roda via /docker-entrypoint.d/ da imagem oficial do nginx, que executa os
# scripts com `set -e` antes de subir o servidor. Entao sair com erro aqui
# derruba o container de proposito: e melhor o site cair de forma barulhenta
# do que subir aberto em silencio.

set -e

# O default.conf da imagem reaparece em runtime mesmo tendo sido removido no
# build. Como ele vem antes na ordem alfabetica do include, virava o servidor
# padrao e atendia tudo sem senha. Remover aqui, antes do nginx subir, e o
# unico jeito deterministico.
if [ -f /etc/nginx/conf.d/default.conf ]; then
    echo "removendo /etc/nginx/conf.d/default.conf (reapareceu em runtime)"
    rm -f /etc/nginx/conf.d/default.conf
fi

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

# Trava de seguranca. Ja aconteceu de tudo aqui dar certo (script rodou, senha
# gerada, config copiada, ate o auth_basic aparecendo no `nginx -T`) e mesmo
# assim o site subir aberto, porque o default.conf tambem estava carregado e,
# vindo antes na ordem alfabetica do include, era ele quem atendia. Falha
# silenciosa de autenticacao e o pior modo de falha possivel, entao aqui a gente
# confere as duas coisas e derruba o boot se qualquer uma falhar.
CONFIG_EFETIVA=$(nginx -T 2>/dev/null || true)

if ! echo "$CONFIG_EFETIVA" | grep -q "auth_basic_user_file"; then
    echo "ERRO: auth_basic nao esta na config efetiva do nginx." >&2
    exit 1
fi

# Este e o check que importa de verdade: nenhum outro server pode estar
# carregado junto, senao ele pode atender no lugar do nosso, sem senha.
if echo "$CONFIG_EFETIVA" | grep -q "^# configuration file /etc/nginx/conf.d/default.conf"; then
    echo "ERRO: default.conf continua carregado e pode atender sem senha." >&2
    exit 1
fi

echo "config efetiva do nginx:"
echo "$CONFIG_EFETIVA" | grep -E "^# configuration file" | sed 's/^/  /'
