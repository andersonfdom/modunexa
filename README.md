# 🪵 ModuNexa

> Plataforma full stack para gestão inteligente de marcenarias, integrando processos comerciais, operacionais e produtivos em uma única solução.

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![Python](https://img.shields.io/badge/Python-3.13-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-API-009688)
![React](https://img.shields.io/badge/React-Frontend-61DAFB)
![License](https://img.shields.io/badge/license-a%20definir-lightgrey)

---

## 📌 Sobre o projeto

A **ModuNexa** é uma plataforma full stack criada para apoiar a transformação digital de marcenarias e empresas de móveis planejados.

O objetivo é centralizar processos que normalmente ficam distribuídos entre planilhas, documentos, sistemas isolados e controles manuais.

A plataforma está sendo projetada para integrar:

- gestão de clientes;
- elaboração de orçamentos;
- ambientes e projetos;
- materiais e tabelas de preços;
- contratos;
- CRM comercial;
- acompanhamento da produção;
- cronogramas;
- documentos e arquivos;
- automação de processos;
- recursos de Inteligência Artificial.

Além de solucionar um problema de negócio real, o projeto é utilizado para aplicar conceitos modernos de **Backend Engineering, desenvolvimento Full Stack e IA aplicada a software**.

---

## 🎯 Problema que a ModuNexa pretende resolver

Uma marcenaria pode precisar administrar diferentes informações durante o ciclo de um projeto:

```text
Cliente
   ↓
Orçamento
   ↓
Negociação
   ↓
Contrato
   ↓
Projeto
   ↓
Compra de materiais
   ↓
Produção
   ↓
Entrega
   ↓
Montagem
   ↓
Finalização
```

Quando essas informações estão distribuídas entre planilhas, PDFs, mensagens e controles manuais, aumentam as chances de retrabalho, inconsistências e perda de informações.

A ModuNexa pretende centralizar esse fluxo e utilizar Inteligência Artificial como apoio às atividades que envolvem análise de dados e documentos.

---

## 🏗️ Arquitetura do projeto

O projeto utiliza uma estrutura de **monorepo**, mantendo backend e frontend no mesmo repositório.

```text
modunexa/
│
├── backend/
│   ├── database/
│   │   └── modunexa.sql
│   │
│   └── modunexa-api/
│       ├── src/
│       │   └── modunexa/
│       │       ├── core/
│       │       ├── modules/
│       │       └── main.py
│       │
│       ├── tests/
│       ├── pyproject.toml
│       └── uv.lock
│
├── frontend/
│   └── ...
│
├── .editorconfig
├── .gitignore
└── README.md
```

---

## ⚙️ Backend

A API está sendo desenvolvida utilizando **Python 3.13 e FastAPI**.

### Tecnologias atuais

| Tecnologia | Finalidade |
|---|---|
| Python 3.13 | Linguagem principal do backend |
| FastAPI | Desenvolvimento da API REST |
| Uvicorn | Servidor ASGI |
| Pydantic | Validação e tipagem de dados |
| uv | Gerenciamento de ambiente e dependências |
| OpenAPI | Especificação da API |
| Swagger UI | Documentação interativa |

### Tecnologias previstas

Durante a evolução do backend serão incorporadas:

- PostgreSQL;
- SQLAlchemy 2;
- Alembic;
- Pydantic Settings;
- Pytest;
- Ruff;
- Mypy;
- autenticação JWT/OAuth2;
- Docker;
- GitHub Actions;
- pgvector;
- integração com modelos de IA;
- embeddings;
- RAG.

---

## ⚛️ Frontend

O frontend será desenvolvido utilizando **React** e consumirá a API REST disponibilizada pelo backend.

A interface será responsável pela interação com módulos como:

- dashboard;
- clientes;
- orçamentos;
- materiais;
- contratos;
- CRM;
- produção;
- cronograma;
- documentos;
- assistente de IA.

> 🚧 O frontend ainda será iniciado.

---

## 🧩 Domínios da plataforma

A arquitetura está sendo preparada para contemplar diferentes áreas do negócio.

### 👥 Clientes

Cadastro e gerenciamento das informações dos clientes e profissionais relacionados aos projetos.

### 📐 Ambientes

Organização dos projetos por ambientes, como cozinha, dormitórios, banheiros, sala, área gourmet e outros.

### 🧮 Orçamentos

Elaboração de orçamentos considerando:

- ambientes;
- categorias;
- itens;
- dimensões;
- materiais;
- quantidades;
- regras de cálculo;
- descontos;
- acréscimos;
- RT.

### 🪚 Materiais e catálogo

Gerenciamento de:

- materiais;
- categorias;
- produtos;
- preços;
- fornecedores;
- histórico de alterações.

### 📄 Contratos

Geração e gerenciamento dos contratos relacionados aos projetos aprovados.

### 📊 CRM

Acompanhamento do processo comercial por meio de etapas de negociação.

Exemplo:

```text
Novo lead
   ↓
Negociação
   ↓
Proposta enviada
   ↓
Fechamento
```

### 🏭 Produção

Acompanhamento do projeto após o fechamento comercial.

Fluxo inicialmente planejado:

```text
Projeto pronto
   ↓
Material comprado
   ↓
Material cortado
   ↓
Marcenaria pronta
   ↓
Entregue
   ↓
Montando
   ↓
Finalizado
```

### 📅 Cronograma

Controle de eventos relacionados a:

- medição;
- aprovação;
- produção;
- entrega;
- montagem;
- assistência técnica.

---

## 🤖 Inteligência Artificial

A IA será incorporada como **recurso de apoio aos processos da marcenaria**, e não apenas como um chatbot isolado.

Entre os recursos planejados estão:

### Análise de documentos

Processamento de:

- contratos;
- projetos;
- especificações;
- tabelas de preços;
- documentos PDF.

### Planilhas

Importação e análise de arquivos contendo informações como:

- materiais;
- produtos;
- categorias;
- preços;
- ambientes.

### Assistente contextual

Consulta em linguagem natural às informações disponíveis na plataforma.

Exemplos de futuras consultas:

```text
"Quais ambientes fazem parte deste projeto?"

"Quais materiais tiveram alteração de preço?"

"Qual é o prazo previsto para este cliente?"

"Compare o orçamento atual com a versão anterior."
```

### RAG

A arquitetura futura prevê **Retrieval-Augmented Generation (RAG)** para permitir que modelos de linguagem utilizem documentos e informações pertencentes à própria marcenaria como contexto.

---

## 🚀 Executando o backend

### Pré-requisitos

- Python 3.13+
- uv

Clone o projeto:

```bash
git clone https://github.com/andersonfdom/modunexa.git
```

Entre no diretório da API:

```bash
cd modunexa/backend/modunexa-api
```

Instale/sincronize as dependências:

```bash
uv sync
```

Execute a aplicação:

```bash
uv run uvicorn src.modunexa.main:app --reload --port 8001
```

A API estará disponível em:

```text
http://127.0.0.1:8001
```

---

## ❤️ Health Check

Para verificar se a API está disponível:

```http
GET /health
```

Resposta atual:

```json
{
  "status": "ok"
}
```

---

## 📚 Documentação da API

O FastAPI gera automaticamente a especificação OpenAPI e uma interface Swagger.

Com a aplicação em execução:

**Swagger UI**

```text
http://127.0.0.1:8001/docs
```

**OpenAPI JSON**

```text
http://127.0.0.1:8001/openapi.json
```

---

## 🗺️ Roadmap

### Fundação

- [x] Estrutura inicial do monorepo
- [x] Configuração do Python 3.13
- [x] Gerenciamento de dependências com uv
- [x] API inicial com FastAPI
- [x] Health Check
- [x] Swagger / OpenAPI
- [ ] Configuração por variáveis de ambiente

### Backend

- [ ] PostgreSQL
- [ ] SQLAlchemy 2
- [ ] Alembic
- [ ] Autenticação e autorização
- [ ] Gestão de marcenarias
- [ ] Gestão de usuários
- [ ] Gestão de clientes
- [ ] Ambientes
- [ ] Catálogo e materiais
- [ ] Motor de orçamento
- [ ] Contratos
- [ ] CRM
- [ ] Produção
- [ ] Cronograma

### Documentos e IA

- [ ] Upload de arquivos
- [ ] Importação de planilhas
- [ ] Processamento de PDFs
- [ ] Integração com LLM
- [ ] Embeddings
- [ ] Busca semântica
- [ ] RAG
- [ ] Assistente contextual

### Qualidade e DevOps

- [ ] Testes unitários
- [ ] Testes de integração
- [ ] Ruff
- [ ] Mypy
- [ ] Docker
- [ ] CI/CD com GitHub Actions

### Frontend

- [ ] Estrutura inicial React
- [ ] Integração com API
- [ ] Autenticação
- [ ] Dashboard
- [ ] Interfaces dos módulos de negócio

---

## 🧠 Conceitos explorados

Durante o desenvolvimento serão estudados e aplicados, quando adequados:

- REST;
- OpenAPI;
- arquitetura modular;
- separação de responsabilidades;
- princípios SOLID;
- Domain-Driven Design;
- Clean Architecture;
- Repository Pattern;
- Dependency Injection;
- type hints;
- programação assíncrona;
- migrations;
- testes automatizados;
- autenticação e autorização;
- observabilidade;
- containers;
- CI/CD;
- processamento de documentos;
- integração com LLMs;
- embeddings;
- busca vetorial;
- RAG.

---

## 📈 Status atual

**Versão:** `0.1.0`

**Fase:** Fundação do backend.

Atualmente, a API FastAPI está configurada e executando com sucesso, incluindo Health Check, OpenAPI e Swagger UI.

O próximo marco do projeto é estruturar a configuração da aplicação e iniciar a camada de persistência.

---

## 👨‍💻 Autor

**Anderson Fernando Domingos**

Projeto desenvolvido para estudo, evolução profissional e aplicação prática de engenharia de software, desenvolvimento full stack e Inteligência Artificial.