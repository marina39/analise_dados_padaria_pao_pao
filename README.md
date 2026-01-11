# 📊 Dashboard de Gestão: Cafeteria Valenet

Este projeto consiste em um pipeline completo de dados (ETL), abrangendo desde a extração de fontes heterogêneas, tratamento de inconsistências técnicas, modelagem em banco de dados relacional (MySQL) até a visualização executiva no Power BI.

## 🛠️ Tecnologias Utilizadas

* **Linguagem:** Python 3.x
* **Bibliotecas:** Pandas, Requests, SQLAlchemy, Lxml (para HTML)
* **Banco de Dados:** MySQL 8.0
* **Visualização:** Power BI
* **Versionamento:** Git

---

## 🏗️ Arquitetura e Fluxo de Dados

O projeto foi estruturado para garantir que dados "sujos" de fontes externas fossem transformados em informações confiáveis para a tomada de decisão.

### 1. Extração (ETL)
Os dados foram consumidos de três origens distintas:
* **Menu:** Arquivo `CSV` (Dados de produtos e preços).
* **Clientes e Membros:** API em formato `JSON` (Dados cadastrais e assinaturas).
* **Vendas:** Web Scraping de tabela `HTML` (Histórico de transações).

### 2. Tratamento e Saneamento (Python/Pandas)
Realizei um processo rigoroso de limpeza para garantir a integridade do modelo:
* **Unificação de Identidade:** Tratamento de IDs de clientes inconsistentes (ex: redirecionamento de registros do ID 4 para o ID 6 ativo), preservando a rastreabilidade histórica.
* **Normalização de Datas:** Conversão de formatos complexos (ex: "01/01/2025 as 09h43") e tratamento de ISO 8601 com remoção de fuso horário para compatibilidade com SQL.
* **Integridade Financeira:** Conversão de valores de centavos para Reais e aplicação de tipagem estrita.
* **Prevenção de Erros (Fail-Fast):** Implementação de validações com `raise ValueError` para impedir a carga de IDs nulos ou inconsistências lógicas no banco.

### 3. Modelagem de Dados (SQL)
A estrutura no MySQL foi desenhada seguindo as melhores práticas de bancos relacionais:
* **Chaves Primárias e Estrangeiras:** Implementação de `PRIMARY KEY` e `FOREIGN KEY` para garantir que vendas e membros estejam devidamente vinculados a clientes e produtos existentes.
* **Tipagem Monetária:** Uso do tipo `DECIMAL(10,2)` na tabela de Menu para evitar erros de arredondamento comuns em tipos `FLOAT`.

### 4. Visualização (Power BI)
O dashboard foi projetado para oferecer duas camadas de análise:
* **Visão Executiva:** KPIs de faturamento, volume de vendas e taxa de conversão de membros.
* **Visão Operacional:** Tabela de detalhamento de pedidos com navegação de página e filtros sincronizados.

---

## 🚀 Como Executar

1.  **Banco de Dados:**
    Execute as queries de criação de tabela (DDL) no seu servidor MySQL.
2.  **Ambiente Python:**
    ```bash
    pip install pandas sqlalchemy mysql-connector-python requests lxml
    ```
3.  **Configuração:**
    Certifique-se de configurar o arquivo `config.py` com suas credenciais de acesso ao banco.
4.  **Execução:**
    Rode o script principal para processar os dados e popular o banco:
    ```bash
    python main.py
    ```

---

## ✒