# CLAUDE.md

## Project Structure

Excalidraw is a **monorepo** with a clear separation between the core library and the application:

- **`packages/excalidraw/`** - Main React component library published to npm as `@excalidraw/excalidraw`
- **`excalidraw-app/`** - Full-featured web application (excalidraw.com) that uses the library
- **`packages/`** - Core packages: `@excalidraw/common`, `@excalidraw/element`, `@excalidraw/math`, `@excalidraw/utils`
- **`examples/`** - Integration examples (NextJS, browser script)

## Development Workflow

1. **Package Development**: Work in `packages/*` for editor features
2. **App Development**: Work in `excalidraw-app/` for app-specific features
3. **Testing**: Always run `yarn test:update` before committing
4. **Type Safety**: Use `yarn test:typecheck` to verify TypeScript

## Development Commands

```bash
yarn test:typecheck  # TypeScript type checking
yarn test:update     # Run all tests (with snapshot updates)
yarn fix             # Auto-fix formatting and linting issues
```

## Architecture Notes

### Package System

- Uses Yarn workspaces for monorepo management
- Internal packages use path aliases (see `vitest.config.mts`)
- Build system uses esbuild for packages, Vite for the app
- TypeScript throughout with strict configuration

## Fork / deploy (nao existe no upstream)

- Fork de `excalidraw/excalidraw`. Branch default: `master`. Sincronizar com
  `git fetch upstream && git merge upstream/master`.
- Deploy: Railway, servico `excalidraw`, builder Dockerfile via
  `RAILWAY_DOCKERFILE_PATH=Dockerfile.railway`.
- **Use `Dockerfile.railway`, nao o `Dockerfile`.** O do upstream usa
  `FROM --platform=${BUILDPLATFORM}` e `RUN --mount=type=cache`; o builder do
  Railway rejeita as duas e o build morre em segundos **sem gerar log nenhum**.
  Nao adicione sintaxe BuildKit nesse arquivo.
- **Porta: 80.** nginx nao le `$PORT`; o dominio do Railway aponta pra 80.
- **Senha de acesso** via Basic Auth, gerada no boot a partir da variavel
  `APP_PASSWORD` do Railway (usuario: `APP_USER`, padrao `excalidraw`). Sem a
  variavel o container se recusa a subir, de proposito.
- **Nao confie em remover o `default.conf` do nginx no build** — ele reaparece
  em runtime e, por vir antes na ordem alfabetica do `include conf.d/*.conf`,
  vira o servidor padrao e serve tudo **sem senha**, mesmo com a config certa
  carregada logo depois. Quem remove de fato e o `docker/40-htpasswd.sh`, no
  boot, que tambem derruba o container se isso regredir.
- **Variavel setada no painel do Railway nao chega no bundle.** As `VITE_APP_*`
  sao embutidas em build-time pelo Vite; o Dockerfile so declara `ARG NODE_ENV`.
  Pra mudar endpoint, edite `.env.production` ou adicione `ARG`/`ENV` no
  Dockerfile.railway.

Historico de decisoes: `docs/DIARIO.md`
