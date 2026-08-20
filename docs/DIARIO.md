# Diario — excalidraw (fork)

Historico de decisoes. Nao e carregado em toda sessao — lido sob demanda.
Entrada nova no topo, com data.

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
