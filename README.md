# ModuNexa

Plataforma full stack inteligente para gestão de marcenarias.

A ModuNexa está sendo desenvolvida para apoiar processos comerciais, operacionais e produtivos de marcenarias, integrando gestão de clientes, orçamentos, contratos, produção, documentos e recursos de Inteligência Artificial.

## Arquitetura

```text
modunexa/
├── backend/
│   └── modunexa-api/
│       └── Python + FastAPI
│
├── frontend/
│   └── React
│
├── .editorconfig
├── .gitignore
└── README.md

Backend

O backend está sendo desenvolvido com:

Python 3.13
FastAPI
Uvicorn
Pydantic
uv
OpenAPI / Swagger

Tecnologias previstas:

PostgreSQL
SQLAlchemy 2
Alembic
Pytest
Ruff
Mypy
Docker
JWT / OAuth2
pgvector
Inteligência Artificial
RAG
Frontend

O frontend será desenvolvido com React.

A camada frontend consumirá a API REST da ModuNexa e será responsável pelas interfaces de:

clientes
orçamentos
materiais
contratos
CRM
produção
cronograma
documentos
recursos de IA
Recursos planejados

A plataforma será composta por módulos como:

gestão de marcenarias
usuários e autenticação
cadastro de clientes
cadastro de ambientes
categorias e materiais
geração de orçamentos
regras de cálculo
contratos
CRM comercial
gestão de produção
cronograma
upload de arquivos
importação de planilhas
processamento de PDFs
Inteligência Artificial
RAG e busca semântica
Inteligência Artificial

A ModuNexa será preparada para recursos como:

análise de contratos
interpretação de projetos em PDF
extração de informações de documentos
leitura de planilhas
comparação de preços
identificação de inconsistências
consulta inteligente a documentos
auxílio na geração de orçamentos
Status

Projeto em desenvolvimento.

Backend

API inicial em FastAPI já disponível com:

GET /health

Documentação Swagger:

http://127.0.0.1:8001/docs
Objetivo técnico

Este projeto também tem como objetivo demonstrar conhecimentos de engenharia de software e desenvolvimento full stack utilizando tecnologias modernas.

Entre os conceitos aplicados estarão:

APIs REST
arquitetura modular
Clean Architecture
Domain-Driven Design
SOLID
type hints
validação de dados
banco de dados relacional
migrations
testes automatizados
autenticação e autorização
Docker
CI/CD
integração frontend/backend
processamento assíncrono
integração com modelos de IA
embeddings
RAG
Autor

Anderson Fernando Domingos


Agora confira seu `.gitignore` da **raiz**. Como teremos Python e React no mesmo repositório, ele deve proteger os dois lados. Pode substituir por:

```gitignore
# =========================
# Python
# =========================

.venv/
venv/
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/

# Environment variables
.env
.env.*
!.env.example

# =========================
# Node / React
# =========================

node_modules/
dist/
build/
coverage/
*.local

# =========================
# IDEs
# =========================

.idea/
.vscode/

# =========================
# OS
# =========================

.DS_Store
Thumbs.db

# =========================
# Logs
# =========================

*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*