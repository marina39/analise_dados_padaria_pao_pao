CREATE TABLE `clientes` (
  `cliente_id` int NOT NULL AUTO_INCREMENT,
  `cliente_nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deletado` tinyint(1) DEFAULT '0',
  `dt_delete` datetime DEFAULT NULL,
  PRIMARY KEY (`cliente_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `membros` (
  `membro_id` int NOT NULL AUTO_INCREMENT,
  `cliente_id` int NOT NULL,
  `dt_inicio_assinatura` datetime NOT NULL,
  `dt_fim_assinatura` datetime DEFAULT NULL,
  PRIMARY KEY (`membro_id`),
  KEY `fk_membros_clientes` (`cliente_id`),
  CONSTRAINT `fk_membros_clientes` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`cliente_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `menu` (
  `produto_id` int NOT NULL AUTO_INCREMENT,
  `produto_nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `preco_reais` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`produto_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `vendas` (
  `venda_id` int NOT NULL AUTO_INCREMENT,
  `cliente_id` int NOT NULL,
  `cliente_nome` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `produto_id` int NOT NULL,
  `data_venda` datetime DEFAULT NULL,
  PRIMARY KEY (`venda_id`),
  KEY `fk_vendas_clientes` (`cliente_id`),
  KEY `fk_vendas_menu` (`produto_id`),
  CONSTRAINT `fk_vendas_clientes` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`cliente_id`),
  CONSTRAINT `fk_vendas_menu` FOREIGN KEY (`produto_id`) REFERENCES `menu` (`produto_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1074 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
