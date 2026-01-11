DELIMITER //

CREATE TRIGGER tg_valida_venda_cliente_ativo
BEFORE INSERT ON vendas
FOR EACH ROW
BEGIN
    -- 1. Cria uma variável para armazenar o status do cliente
    DECLARE status_cliente TINYINT DEFAULT 1;

    -- 2. Busca o status 'deletado' na tabela clientes para o nome que está sendo inserido
    -- Usa LIMIT 1 caso existam históricos, priorizando o registro mais recente/ativo
    SELECT deletado INTO status_cliente 
    FROM clientes 
    WHERE cliente_nome = NEW.cliente_nome 
    ORDER BY deletado ASC -- Prioriza o valor 0 (ativo) se houver duplicata
    LIMIT 1;

    -- 3. Se o cliente não existir ou se o status for 1 (deletado), barra a venda
    IF status_cliente = 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'ERRO: Venda não permitida para cliente inativo ou deletado.';
    END IF;
END; //

DELIMITER ;