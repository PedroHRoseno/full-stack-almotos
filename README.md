# AlMotos - Sistema de Gerenciamento de Veículos

Sistema completo full-stack para gestão de concessionária de veículos, desenvolvido com **Kotlin/Spring Boot** no backend e **Next.js/TypeScript** no frontend.

> **Repositório pai + submodules:** Se este monorepo usa Git submodules (`almotos-front` e `vehicle-sales-manager-v2-kotlin` como submódulos), veja o guia **[SUBMODULES_GUIDE.md](./SUBMODULES_GUIDE.md)** para configurar, clonar e trabalhar no dia a dia.

## 📋 Visão Geral

O AlMotos é um sistema de gestão completo que permite:
- Cadastro e gerenciamento de veículos
- Cadastro e gerenciamento de parceiros (clientes e fornecedores)
- Registro de compras de veículos
- Registro de vendas de veículos
- Registro de trocas de veículos
- Relatórios financeiros e dashboard

## 🏗️ Arquitetura

```
full-stack-almotos/
├── vehicle-sales-manager-v2-kotlin/  # Backend (Kotlin/Spring Boot)
│   ├── src/
│   ├── docker-compose.yml
│   └── README.md
├── almotos-front/                    # Frontend (Next.js/TypeScript)
│   ├── src/
│   └── README.md
└── vehicle-sales-manager/            # Backend antigo (Java - referência)
```

## 🚀 Tecnologias

### Backend
- **Kotlin** 1.9+
- **Spring Boot** 3.2.0
- **Spring Data JPA**
- **PostgreSQL** 15
- **Docker Compose**
- **SpringDoc OpenAPI** (Swagger)

### Frontend
- **Next.js** 15 (App Router)
- **React** 19
- **TypeScript**
- **Tailwind CSS**
- **Shadcn UI**
- **React Hook Form** + **Zod**
- **Radix UI**

## 📦 Pré-requisitos

- **Java 17+**
- **Node.js 18+** e npm
- **Docker** e **Docker Compose**
- **Gradle** (ou usar o wrapper incluído)

## 🛠️ Instalação e Execução

### 1. Backend (Kotlin)

```bash
# Navegar para o diretório do backend
cd vehicle-sales-manager-v2-kotlin

# Iniciar o PostgreSQL com Docker Compose
docker-compose up -d

# Compilar o projeto
./gradlew build

# Executar a aplicação
./gradlew bootRun
```

O backend estará disponível em `http://localhost:8080`

**Documentação Swagger**: `http://localhost:8080/swagger-ui.html`

### 2. Frontend (Next.js)

```bash
# Navegar para o diretório do frontend
cd almotos-front

# Instalar dependências
npm install

# Criar arquivo de configuração
echo "NEXT_PUBLIC_API_URL=http://localhost:8080" > .env.local

# Iniciar servidor de desenvolvimento
npm run dev
```

O frontend estará disponível em `http://localhost:3000`

## 📚 Documentação

- **Backend**: Veja [vehicle-sales-manager-v2-kotlin/README.md](./vehicle-sales-manager-v2-kotlin/README.md)
- **Frontend**: Veja [almotos-front/README.md](./almotos-front/README.md)

## 🔑 Funcionalidades Principais

### Backend
- ✅ API REST completa com paginação
- ✅ Busca em tempo real (CPF, nome, placa)
- ✅ Regras de negócio automatizadas:
  - Compra → Veículo fica DISPONIVEL
  - Venda → Veículo fica VENDIDO
  - Troca → Veículo entrada DISPONIVEL, saída VENDIDO
- ✅ Relatórios financeiros com filtros de data
- ✅ Integração com PostgreSQL via Docker
- ✅ Documentação Swagger automática

### Frontend
- ✅ Dashboard com indicadores em tempo real
- ✅ Tabelas paginadas com busca
- ✅ Formulários com validação completa
- ✅ Modais para cadastro/edição
- ✅ Integração ViaCEP para endereços
- ✅ Componentes reutilizáveis (SearchableSelect)
- ✅ UX moderna e responsiva

## 📊 Estrutura de Dados

### Entidades Principais

- **Partner** (Parceiro): Clientes e fornecedores
- **Vehicle** (Veículo): Motos/veículos cadastrados
- **Sale** (Venda): Registro de vendas
- **Purchase** (Compra): Registro de compras
- **Exchange** (Troca): Registro de trocas
- **Address** (Endereço): Endereços dos parceiros

## 🔄 Fluxo de Trabalho

1. **Cadastro de Parceiro**: Cliente ou fornecedor
2. **Cadastro de Veículo**: Pode ser feito isoladamente ou durante uma compra
3. **Registro de Compra**: Vincula veículo a fornecedor, status → DISPONIVEL
4. **Registro de Venda**: Vincula veículo a cliente, status → VENDIDO
5. **Registro de Troca**: Troca entre dois veículos com cálculo de diferença

## 🧪 Testando o Sistema

1. **Inicie o backend** (porta 8080)
2. **Inicie o frontend** (porta 3000)
3. **Acesse** `http://localhost:3000`
4. **Cadastre um parceiro** em "Clientes"
5. **Cadastre um veículo** em "Veículos"
6. **Registre uma compra** em "Compras"
7. **Registre uma venda** em "Vendas"
8. **Visualize o dashboard** para ver os indicadores

## 📝 Notas Importantes

- O backend usa **PostgreSQL** via Docker Compose
- O frontend usa **proxy** para evitar problemas de CORS
- Todos os endpoints suportam **paginação** (padrão: 20 itens)
- A busca é **case-insensitive** e suporta busca parcial
- Os DTOs usam **camelCase** para compatibilidade com TypeScript

## 🐛 Troubleshooting

### Backend não inicia
- Verifique se o PostgreSQL está rodando: `docker-compose ps`
- Verifique as configurações em `application.properties`
- Veja os logs: `docker-compose logs -f postgres`

### Frontend não conecta ao backend
- Verifique se o backend está rodando na porta 8080
- Confirme o arquivo `.env.local` com `NEXT_PUBLIC_API_URL=http://localhost:8080`
- Reinicie o servidor Next.js após alterar `.env.local`

### Erro de CORS
- O backend já está configurado com CORS para `http://localhost:3000`
- Verifique se o proxy está configurado no `next.config.ts`

## 📄 Licença

Este projeto é privado e de uso interno.

## 👥 Desenvolvimento

- **Backend**: Kotlin/Spring Boot
- **Frontend**: Next.js/TypeScript
- **Banco de Dados**: PostgreSQL
- **Containerização**: Docker Compose

## 🔮 Próximas Melhorias

- [ ] Autenticação e autorização
- [ ] Edição de veículos
- [ ] Exportação de relatórios (PDF/Excel)
- [ ] Gráficos no dashboard
- [ ] Testes automatizados
- [ ] CI/CD pipeline
