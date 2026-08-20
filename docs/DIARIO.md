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

**Por que existe `Dockerfile.railway`:** o Dockerfile do upstream comeca com
`FROM --platform=${BUILDPLATFORM} node:24@sha256:...`. O builder do Railway nao
define `BUILDPLATFORM`, entao vira `--platform=` vazio e o BuildKit aborta ao
parsear — falha em ~5s sem escrever uma linha de log, o que torna o erro
praticamente invisivel. Arquivo separado em vez de editar o original pra nao
gerar conflito em todo merge do upstream.

**Sobre a infra da Excalidraw:** com o `.env.production` de fabrica, esta
instancia usa os servidores publicos deles pra link compartilhado
(`json.excalidraw.com`), colaboracao ao vivo (`oss-collab.excalidraw.com`),
persistencia de cena (Firebase `excalidraw-room-persistence`), biblioteca de
formas e text-to-diagram. Desenho local no navegador nao depende de nada disso.
Pra isolar de verdade seria preciso subir o `excalidraw-room` e um Firebase
proprio.

**Pendencias:** os 7 servicos-fantasma do detector de monorepo ainda estao no
projeto (nao aparecem em `railway service list` porque nao tem instancia em
`production`; so somem pelo painel). Branch `main` no GitHub, com so o commit de
esqueleto do `novo-projeto.sh`, ainda existe e nao tem relacao com o historico
do `master`.
