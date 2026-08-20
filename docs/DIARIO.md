# Diario — excalidraw (fork)

Historico de decisoes. Nao e carregado em toda sessao — lido sob demanda.
Entrada nova no topo, com data.

---

## 2026-08-20 — persistencia online no Firebase proprio

`VITE_APP_FIREBASE_CONFIG` passou a apontar pro projeto `excalidraw-b46b8`, via
variavel do servico no Railway + `ARG` no Dockerfile.railway. Nao vai pro git: o
fork e publico e as rules do Excalidraw sao abertas para escrita, entao commitar
a config entregaria de graça o que a senha de acesso protege.

O `ARG` e obrigatorio: sem ele o Vite ignora a variavel do painel sem erro
nenhum, porque as `VITE_APP_*` sao congeladas no bundle em build-time. O build
agora falha se a variavel estiver vazia — sem essa trava ele cairia no valor do
`.env.production`, que aponta pro Firebase da propria Excalidraw, e os desenhos
iriam pro banco deles sem aviso.

**Verificado, nao presumido.** Bundle publicado: 9 ocorrencias de
`excalidraw-b46b8`, e as 2 restantes de `excalidraw-room-persistence` sao o
`VITE_APP_LIBRARY_BACKEND` (catalogo publico de bibliotecas de formas, sem dado
nosso). Firestore pela API REST: escrita 200, leitura 200, **listagem 403** (o
`allow list: if false` valendo, que e o que impede varrer o banco atras dos IDs
das salas), remocao 200 seguida de 404. Documento de teste apagado.

Sondar a API REST do Firestore com a apiKey distingue os estados sem precisar do
console: "API has not been used" = banco nao criado; `PERMISSION_DENIED` = banco
existe mas rules bloqueiam; `NOT_FOUND` num doc inexistente = rules valendo.

**Como usar:** Compartilhar -> Colaboracao ao vivo -> Iniciar sessao. A URL
gerada (`#room=<id>,<chave>`) e o documento persistente — guardar nos favoritos.
Perdeu a URL, perdeu o desenho: a chave de criptografia so existe no fragmento
dela, entao nem com acesso total ao Firestore da pra recuperar.

---

## 2026-08-20 — senha de acesso (Basic Auth)

Basic Auth no nginx, com o `.htpasswd` gerado no boot a partir da variavel
`APP_PASSWORD` do Railway — a senha nunca entra no git nem na imagem. Sem a
variavel o container se recusa a subir: site fora do ar e barulhento, site
aberto em silencio nao.

**A armadilha, que custou tres deploys:** remover o `/etc/nginx/conf.d/default.conf`
no Dockerfile nao funciona. O arquivo reaparece no container em runtime. Como o
nginx faz `include /etc/nginx/conf.d/*.conf` em ordem alfabetica, `default.conf`
vinha antes de `excalidraw.conf`, virava o servidor padrao e atendia tudo sem
senha — com a config correta carregada logo depois, inerte.

O que tornou isso dificil foi o falso negativo em tudo que da pra checar de fora:
o commit deployado era o certo, os `COPY` apareciam no log de build, o script de
boot imprimia sucesso, o `.htpasswd` existia, o CDN estava desligado e o
deployment ativo era o novo. Todos os sinais verdes, e o site aberto. Só um
`nginx -T` no boot, listando os arquivos de config efetivamente carregados,
mostrou os dois arquivos e explicou o caso.

Fica um `nginx -T` de verificacao no boot que derruba o container se o
`default.conf` voltar a ser carregado. Uma checagem so de "`auth_basic` esta na
config?" nao serviria: no estado quebrado ela passava.

**Licao geral:** autenticacao que falha aberta e silenciosa. Nao basta conferir
que a config esta certa — tem que conferir a config *efetiva*, e testar de fora
que sem credencial da 401. Foi o teste externo que pegou; a inspecao do build
nao pegaria nunca.

---

## 2026-08-20 — fork + deploy no Railway

Fork de `excalidraw/excalidraw` em `drudif/excalidraw`, branch default `master`
(mantido igual ao upstream pra sincronizar sem dor). Remote `upstream` aponta pro
repo original com push desabilitado.

**Estado que encontrei no Railway:** o projeto `illustrious-prosperity` tinha 8
servicos criados pelo detector de monorepo (um por workspace do yarn, incluindo
bibliotecas e exemplos), todos sem instancia no ambiente `production`, sem repo
conectado e sem nenhum deploy. Nada tinha subido.

**O que foi feito:**
- Servico novo `excalidraw`, conectado a `drudif/excalidraw` branch `master`,
  root directory na raiz.
- `RAILWAY_DOCKERFILE_PATH=Dockerfile.railway` — forca o builder Dockerfile
  (o default estava caindo em RAILPACK).
- Dominio `excalidraw-production-f2a8.up.railway.app` com **target port 80**
  (nginx nao le a variavel PORT do Railway).

**Por que existe `Dockerfile.railway`:** o Dockerfile do upstream usa duas
construcoes especificas do BuildKit que o builder do Railway nao aceita:
`FROM --platform=${BUILDPLATFORM}` e `RUN --mount=type=cache`. Com qualquer uma
delas o build morre em 5-15s **sem emitir uma unica linha de log** — o painel so
diz "Failed to build an image. Please check the build logs", e os logs estao
vazios. Foram 4 deploys falhos ate isolar. Removendo as duas (mais o digest
pinado e o `npm_config_target_arch=${TARGETARCH}`, que ja era inerte porque
TARGETARCH nunca foi declarado com ARG), o build passou em ~90s.

Regra pratica: no Railway, build que falha em segundos e sem log = erro de
parse do Dockerfile, nao erro da aplicacao.

Arquivo separado em vez de editar o original pra nao gerar conflito em todo
merge do upstream.

**Resultado:** online em https://excalidraw-production-f2a8.up.railway.app —
HTML, bundle JS (2,1 MB) e CSS servindo 200. Rota desconhecida da 404, o que e
esperado: o Excalidraw usa hash routing (`#json=`, `#room=`), entao nao precisa
de fallback SPA no nginx.

**Sobre a infra da Excalidraw:** com o `.env.production` de fabrica, esta
instancia usa os servidores publicos deles pra link compartilhado
(`json.excalidraw.com`), colaboracao ao vivo (`oss-collab.excalidraw.com`),
persistencia de cena (Firebase `excalidraw-room-persistence`), biblioteca de
formas e text-to-diagram. Desenho local no navegador nao depende de nada disso.
Pra isolar de verdade seria preciso subir o `excalidraw-room` e um Firebase
proprio.

**Pendencias:** os 7 servicos-fantasma do detector de monorepo ainda estao no
projeto. Nao aparecem em `railway service list` nem aceitam `service delete`
porque nunca ganharam instancia no ambiente `production` — so somem pelo painel.

**Nao-problema:** o branch `main` que parecia existir no GitHub era ref local
desatualizado; o push do `novo-projeto.sh` nunca chegou no remote. O repo sempre
teve so `master`.
