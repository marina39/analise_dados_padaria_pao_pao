-- 1. Qual o total gasto por cada cliente da padaria?
SELECT
	v.cliente_nome,
    SUM(m.preco_reais) as total_gasto
FROM vendas v
JOIN menu m ON v.produto_id = m.produto_id
GROUP BY v.cliente_nome
ORDER BY v.cliente_nome;

-- 2. Quantos dias cada cliente realizou ao menos um pedido na padaria?
SELECT
	cliente_nome,
    COUNT(DISTINCT DATE(data_venda)) as dias_visitados
FROM vendas
GROUP BY cliente_nome;

-- 3. Qual foi o primeiro pedido de cada cliente da padaria?
SELECT
	v.cliente_nome,
    v.data_venda,
    m.produto_nome
FROM vendas v
JOIN menu m ON v.produto_id = m.produto_id
WHERE v.data_venda IN (
	SELECT MIN(data_venda)
    FROM vendas
    GROUP BY cliente_nome
)
ORDER BY v.cliente_nome;

-- 4. Qual é o item mais pedido do cardápio? Quantas vezes esse item foi pedido?
SELECT 
	m.produto_nome,
    COUNT(v.produto_id) as quantidade_pedidos
FROM vendas v
JOIN menu m ON v.produto_id = m.produto_id
GROUP BY m.produto_nome
ORDER BY quantidade_pedidos DESC
LIMIT 1;

-- 5. Qual é o item mais pedido por cada cliente?
SELECT cliente_nome, produto_nome, total_pedidos
FROM (
    SELECT 
        v.cliente_nome, 
        m.produto_nome, 
        COUNT(*) AS total_pedidos,
        -- RANK() garante que se 3 produtos tiverem a mesma quantidade máxima,
        -- os 3 receberão o número 1.
        RANK() OVER(PARTITION BY v.cliente_nome ORDER BY COUNT(*) DESC) as posicao
    FROM vendas v
    JOIN menu m ON v.produto_id = m.produto_id
    GROUP BY v.cliente_nome, m.produto_nome
) AS resumo_favoritos
WHERE posicao = 1;

-- 6. Qual foi o primeiro item que cada cliente pediu após se tornar um membro?
WITH ComprasMembros AS (
    SELECT 
        v.cliente_nome, 
        v.data_venda, 
        m_menu.produto_nome,
        ROW_NUMBER() OVER(
            PARTITION BY v.cliente_nome 
            ORDER BY v.data_venda ASC
        ) as ordem_da_compra
    FROM vendas v
    JOIN clientes c ON v.cliente_nome = c.cliente_nome
    JOIN membros mem ON c.cliente_id = mem.cliente_id
    JOIN menu m_menu ON v.produto_id = m_menu.produto_id
    WHERE v.data_venda >= mem.dt_inicio_assinatura
)
SELECT 
    cliente_nome, 
    data_venda, 
    produto_nome
FROM ComprasMembros
WHERE ordem_da_compra = 1;

-- 7.  Qual foi o último item pedido por cada cliente logo antes de se tornar membro?
WITH ComprasAntesMembro AS (
    SELECT 
        v.cliente_nome, 
        v.data_venda, 
        m_menu.produto_nome,
        ROW_NUMBER() OVER(
            PARTITION BY v.cliente_nome 
            ORDER BY v.data_venda DESC
        ) as ordem_da_compra
    FROM vendas v
    JOIN clientes c ON v.cliente_nome = c.cliente_nome
    JOIN membros mem ON c.cliente_id = mem.cliente_id
    JOIN menu m_menu ON v.produto_id = m_menu.produto_id
    WHERE v.data_venda < mem.dt_inicio_assinatura
)
SELECT 
    cliente_nome, 
    data_venda, 
    produto_nome
FROM ComprasAntesMembro
WHERE ordem_da_compra = 1;

-- 8. Qual é o total de itens pedidos por cada cliente antes de se tornar membro?
SELECT 
    v.cliente_nome, 
    COUNT(v.produto_id) AS total_itens_pre_assinatura
FROM vendas v
JOIN clientes c ON v.cliente_nome = c.cliente_nome
JOIN membros mem ON c.cliente_id = mem.cliente_id
WHERE v.data_venda < mem.dt_inicio_assinatura
GROUP BY v.cliente_nome
ORDER BY v.cliente_nome;

-- 9. Qual é o total gasto por cada cliente antes de se tornar membro?
SELECT 
    v.cliente_nome, 
    SUM(m_menu.preco_reais) AS total_gasto_pre_assinatura
FROM vendas v
JOIN clientes c ON v.cliente_nome = c.cliente_nome
JOIN membros mem ON c.cliente_id = mem.cliente_id
JOIN menu m_menu ON v.produto_id = m_menu.produto_id
WHERE v.data_venda < mem.dt_inicio_assinatura
GROUP BY v.cliente_nome
ORDER BY v.cliente_nome;

-- 10. Dado que cada R$1,00 gasto vale 10 pontos e o "Pão de Queijo un." tem um multiplicador 2x, 
-- quantos pontos cada cliente teria?
SELECT 
    v.cliente_nome,
    SUM(
        CASE 
            WHEN m.produto_nome = 'Pão de Queijo un.' THEN m.preco_reais * 20
            ELSE m.preco_reais * 10
        END
    ) AS total_pontos_fidelidade
FROM vendas v
JOIN menu m ON v.produto_id = m.produto_id
GROUP BY v.cliente_nome
ORDER BY total_pontos_fidelidade DESC;

-- 11. Dado que cada R$1,00 gasto vale 10 pontos e que na primeira semana após um cliente se tornar membro 
-- (período de 7 dias corridos, incluindo o dia de ingresso) ele ganhe um multiplicador 2x em todos os itens. 
-- Quantos pontos teriam os clientes Samuel e Daniel ao final de fevereiro?
SELECT 
    v.cliente_nome,
    SUM(
        CASE 
            -- Regra 1: Se estiver na primeira semana (entre adesão e adesão + 6 dias) -> 20 pontos/real
            WHEN v.data_venda BETWEEN mem.dt_inicio_assinatura AND DATE_ADD(mem.dt_inicio_assinatura, INTERVAL 6 DAY) 
                THEN m.preco_reais * 20
            
            -- Regra 2: Se for Pão de Queijo (fora da primeira semana) -> 20 pontos/real
            WHEN m.produto_nome = 'Pão de Queijo un.' 
                THEN m.preco_reais * 20
            
            -- Regra 3: Outros produtos (fora da primeira semana) -> 10 pontos/real
            ELSE m.preco_reais * 10
        END
    ) AS total_pontos_fevereiro
FROM vendas v
JOIN clientes c ON v.cliente_nome = c.cliente_nome
JOIN membros mem ON c.cliente_id = mem.cliente_id
JOIN menu m ON v.produto_id = m.produto_id
WHERE v.data_venda <= '2025-02-28'
  AND v.cliente_nome IN ('Samuel', 'Daniel')
GROUP BY v.cliente_nome
ORDER BY v.cliente_nome;
   