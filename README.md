# FP&A Executive Dashboard & Data Pipeline

Projeto prático de Planejamento e Análise Financeira (FP&A) focado em acompanhar a performance real (Actual) versus o planejado (Budget), além de analisar margens operacionais e variações por segmento.

---

##  Tecnologias Utilizadas
- **PostgreSQL**: Modelagem do banco relacional em esquema estrela (Star Schema) e criação de Views para consolidação da DRE e cálculo de variações.
- **Microsoft Excel**: Dashboard executivo dinâmico com filtros interativos (Slicers) e tabelas dinâmicas.
- **Power BI**: Painel interativo para acompanhamento visual de KPIs e tendências.

---

##  Principais Métricas e KPIs (2026)
- **Receita Realizada:** R$ 74,30 Mi
- **Variação vs. Orçamento:** -3,19% (desvio de receita)
- **Lucro Bruto:** R$ 24,59 Mi
- **Margem Bruta:** 33,09%
- **Lucro Operacional:** R$ 22,59 Mi

---

##  Estrutura do Banco de Dados (SQL)
O banco foi construído em PostgreSQL dividindo as informações em tabelas fato e dimensão:
- **Tabelas Dimensão:** `dimcustomer` (Clientes e Regiões), `dimproduct` (Produtos e Categorias), `dimdate` (Calendário).
- **Tabelas Fato:** `factsales` (Vendas), `factexpenses` (Despesas Operacionais), `factbudget` (Orçamento).
- **Views Analíticas:**
  - `vw_sales_analysis`: Consolida vendas, produtos e margem bruta percentual por transação.
  - `vw_expenses_analysis`: Agrupa despesas por departamento e centro de custo.
  - `vw_budget_vs_actual`: Une vendas e despesas ao orçamento mensal para calcular a variação percentual da receita e o lucro operacional final.

---

##  Arquivos Disponíveis no Repositório
- `fpa_pipeline_analysis.sql`: Script com a criação de todas as tabelas, chaves e views.
- `fpa_executive_dashboard.xlsx`: Painel em Excel com dashboards e filtros.
- `fpa_dashboard.pbix`: Arquivo do Power BI.

---
Desenvolvido por Gabriel Henrique como projeto de portfólio para Finanças / FP&A.
Linkedin: **www.linkedin.com/in/gabriel-henrique-de-souza-cardoso-9aa9b7217**

---

## 👤 Autor
Projeto desenvolvido para fins de portfólio profissional e demonstração de competências técnicas em FP&A e Análise de Dados.
