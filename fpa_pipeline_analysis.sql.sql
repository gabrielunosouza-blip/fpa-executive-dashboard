-- ============================================================
-- PROJETO FP&A: PIPELINE DE DADOS FINANCEIROS E ANÁLISE DE VARIÂNCIA
-- Banco de Dados: PostgreSQL
-- Autor: [Seu Nome]
-- ============================================================

-- ------------------------------------------------------------
-- 1. ESTRUTURA DO MODELO DE DADOS (DIMENSÕES E TABELAS FATO)
-- ------------------------------------------------------------

-- Tabela Dimensão: Clientes
CREATE TABLE public.dimcustomer (
    customer_id INTEGER NOT NULL PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),      -- Segmentação de mercado (ex: Corporate, Consumer)
    city VARCHAR(50),
    state VARCHAR(2),
    region VARCHAR(30)        -- Região geográfica (ex: Sudeste, Nordeste)
);

-- Tabela Dimensão: Produtos
CREATE TABLE public.dimproduct (
    product_id INTEGER NOT NULL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),     -- Categoria (ex: Eletrônicos, Móveis)
    subcategory VARCHAR(50),
    unit_cost NUMERIC(10,2) CHECK (unit_cost >= 0),
    unit_price NUMERIC(10,2) CHECK (unit_price >= unit_cost)
);

-- Tabela Dimensão: Calendário
CREATE TABLE public.dimdate (
    date DATE NOT NULL PRIMARY KEY,
    year INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    quarter INTEGER
);

-- Tabela Fato: Vendas Realizadas (Actual Sales)
CREATE TABLE public.factsales (
    sale_id INTEGER NOT NULL PRIMARY KEY,
    sale_date DATE REFERENCES public.dimdate(date),
    product_id INTEGER REFERENCES public.dimproduct(product_id),
    customer_id INTEGER REFERENCES public.dimcustomer(customer_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC(10,2) CHECK (unit_price >= 0),
    discount NUMERIC(10,2) CHECK (discount >= 0),
    revenue NUMERIC(12,2) CHECK (revenue >= 0),
    cost NUMERIC(12,2) CHECK (cost >= 0),
    gross_profit NUMERIC(12,2),
    CONSTRAINT chk_gross_profit CHECK (ABS(gross_profit - (revenue - cost)) <= 0.01)
);

-- Tabela Fato: Despesas Operacionais Realizadas (Actual Expenses)
CREATE TABLE public.factexpenses (
    expense_id INTEGER NOT NULL PRIMARY KEY,
    expense_date DATE REFERENCES public.dimdate(date),
    department VARCHAR(50),
    expense_category VARCHAR(50),
    amount NUMERIC(12,2) CHECK (amount >= 0)
);

-- Tabela Fato: Meta Orçamentária (Budget)
CREATE TABLE public.factbudget (
    budget_id INTEGER NOT NULL PRIMARY KEY,
    budget_date DATE REFERENCES public.dimdate(date),
    department VARCHAR(50),
    budget_revenue NUMERIC(12,2) CHECK (budget_revenue >= 0),
    budget_cost NUMERIC(12,2) CHECK (budget_cost >= 0),
    budget_expenses NUMERIC(12,2) CHECK (budget_expenses >= 0)
);


-- ------------------------------------------------------------
-- 2. VIEWS ANALÍTICAS PARA O DASHBOARD (EXCEL / POWER BI)
-- ------------------------------------------------------------

-- VIEW 1: Análise Detalhada de Vendas por Produto e Cliente
-- Conecta as tabelas fato de vendas com as dimensões e calcula a Margem Bruta (%)
CREATE OR REPLACE VIEW public.vw_sales_analysis AS 
SELECT 
    s.sale_id,
    s.sale_date,
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    c.customer_id,
    c.customer_name,
    c.segment,
    c.city,
    c.state,
    c.region,
    s.quantity,
    s.unit_price,
    s.discount,
    s.revenue,
    s.cost,
    s.gross_profit,
    -- Cálculo dinâmico da Margem Bruta Percentual
    ROUND(((s.gross_profit / NULLIF(s.revenue, 0)) * 100), 2) AS gross_margin_pct
FROM public.factsales s
JOIN public.dimproduct p ON s.product_id = p.product_id
JOIN public.dimcustomer c ON s.customer_id = c.customer_id;


-- VIEW 2: Análise de Despesas Operacionais
CREATE OR REPLACE VIEW public.vw_expenses_analysis AS 
SELECT 
    expense_id,
    expense_date,
    DATE_TRUNC('month', expense_date)::DATE AS month,
    department,
    expense_category,
    amount
FROM public.factexpenses;


-- VIEW 3: DRE Abreviada e Análise de Variância (Actual vs. Budget)
-- Consolida Realizado vs. Orçado mensalmente e calcula variações e Lucro Operacional
CREATE OR REPLACE VIEW public.vw_budget_vs_actual AS 
WITH actual_monthly AS (
    -- Agrupamento mensal de Vendas (Receita, Custo e Lucro Bruto)
    SELECT 
        DATE_TRUNC('month', sale_date)::DATE AS month,
        SUM(revenue) AS actual_revenue,
        SUM(cost) AS actual_cost,
        SUM(gross_profit) AS actual_gross_profit
    FROM public.factsales
    GROUP BY DATE_TRUNC('month', sale_date)
),
expenses_monthly AS (
    -- Agrupamento mensal de Despesas Operacionais
    SELECT 
        DATE_TRUNC('month', expense_date)::DATE AS month,
        SUM(amount) AS actual_expenses
    FROM public.factexpenses
    GROUP BY DATE_TRUNC('month', expense_date)
)
SELECT 
    b.budget_date AS month,
    -- Consolidação de Receita Realizada vs Orçada
    a.actual_revenue,
    b.budget_revenue,
    (a.actual_revenue - b.budget_revenue) AS revenue_variance,
    ROUND((((a.actual_revenue - b.budget_revenue) / NULLIF(b.budget_revenue, 0)) * 100), 2) AS revenue_variance_pct,
    
    -- Consolidação de Custo Realizado vs Orçado
    a.actual_cost,
    b.budget_cost,
    (a.actual_cost - b.budget_cost) AS cost_variance,
    
    -- Lucro Bruto Realizado
    a.actual_gross_profit,
    
    -- Consolidação de Despesas Realizadas vs Orçadas
    e.actual_expenses,
    b.budget_expenses,
    (e.actual_expenses - b.budget_expenses) AS expense_variance,
    
    -- Cálculo do Lucro Operacional Realizado (Lucro Bruto - Despesas Operacionais)
    ROUND(((a.actual_revenue - a.actual_cost) - e.actual_expenses), 2) AS operating_profit

FROM public.factbudget b
LEFT JOIN actual_monthly a ON a.month = b.budget_date
LEFT JOIN expenses_monthly e ON e.month = b.budget_date;