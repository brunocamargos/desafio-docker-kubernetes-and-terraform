# Mural de Recados

Front (nginx) + API (Go) + Postgres, do compose a um cluster kind via Terraform.

[Enunciado](docs/enunciado.md) · [Arquitetura](docs/arquitetura.md)

## Pré-requisitos

- Docker
- [mise](https://mise.jdx.dev/)

```bash
mise install
cp .env.example .env
```

## Rodar com compose

```bash
docker compose up --build
```

Acesse http://localhost:8080. Para parar, use `docker compose down`. Para também zerar o banco, use `docker compose down -v`.

## Imagens

```bash
docker build -f app/docker/api.Dockerfile -t mural-api:local app
docker build -f app/docker/web.Dockerfile -t mural-web:local app
```

| Imagem da API | Tamanho |
|---|---:|
| Antes: `golang:1.23-alpine` + `go build` | 620 MB |
| Depois: multi-stage → distroless | 26,6 MB |

## Helm

```bash
helm install mural infra/helm/mural -n mural --create-namespace \
  --set postgres.password=<senha> --wait
```

Acesse http://mural.localtest.me. O chart precisa de um cluster com Traefik e das imagens `mural-api:local` e `mural-web:local`.

## Decisões

- Credenciais no `.env`, fora do git.
- `pg_isready -h 127.0.0.1`: sem o `-h`, o healthcheck marca o banco como pronto ainda durante o `initdb`.
- O nginx recebe só os arquivos estáticos, para não expor o template.
- Distroless em vez de scratch, porque já traz usuário `nonroot` e certificados CA.
- `go build` sem flags: na alpine, o binário já sai estático.
- A senha não fica no `values.yaml`: é obrigatória no install e vira um `Secret`.
- A migração é um Job comum com a revisão no nome, recriado a cada release. Um hook `post-install` trava com `--wait`, porque o Helm espera a API ficar pronta antes de rodar o hook.
- Postgres com readiness em `pg_isready -h 127.0.0.1` (TCP) e liveness em `pg_isready` (socket), que passa durante o `initdb`.
