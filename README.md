# Mural de Recados

Front (nginx) + API (Go) + Postgres, do compose a um cluster kind via Terraform.


## Pré-requisitos

- Docker
- [mise](https://mise.jdx.dev/) ativado no shell (ou use `mise exec -- <comando>`)

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

## Terraform

```bash
cd infra/terraform
terraform init
terraform apply
terraform destroy
```

O `apply` cria o cluster kind, builda e carrega as imagens, instala o Traefik e o chart. Acesse http://mural.localtest.me. A porta 80 precisa estar livre.

## Helm (sem Terraform)

```bash
helm install mural infra/helm/mural -n mural --create-namespace \
  --set postgres.password=<senha> --wait
```

Acesse http://mural.localtest.me. O chart precisa de um cluster com Traefik e das imagens `mural-api:local` e `mural-web:local`.

## Decisões

- Credenciais no `.env`, fora do git.
- `pg_isready -h 127.0.0.1`: sem o `-h`, o healthcheck marca o banco como pronto ainda durante o `initdb`.
- `go build` sem flags: na alpine, o binário já sai estático.
- A migração é um Job comum com a revisão no nome, recriado a cada release. Um hook `post-install` trava com `--wait`, porque o Helm espera a API ficar pronta antes de rodar o hook.
- Postgres com readiness em `pg_isready -h 127.0.0.1` (TCP) e liveness em `pg_isready` (socket), que passa durante o `initdb`.
- A senha do banco é gerada pelo `random_password` e fica só no state, que está fora do git.
- As imagens usam a tag fixa `local` e são buildadas quando o cluster é criado. Para publicar uma mudança de código, rode `terraform apply -replace=terraform_data.images` e reinicie os pods.