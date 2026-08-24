/*
 ModuNexa - schema MariaDB 10.11+
 Plataforma SaaS/API para marcenarias com orçamentos, contratos, CRM,
 produção, cronograma, importação de planilhas/PDF e recursos de IA/RAG.

 Decisões principais:
 - Multi-tenant por marcenaria_id.
 - Senhas/tokens sempre em hash; nunca credenciais em texto puro.
 - Arquivos fora do banco (S3/MinIO/Azure Blob etc.); banco guarda metadados/URI.
 - Orçamentos guardam "snapshot" dos preços/regras usados, preservando histórico.
 - Fórmulas de preço são tipadas e parametrizadas; não executar expressão textual do usuário.
 - IA usa texto extraído + chunks e vector_external_id (compatível com MariaDB 10.11).
*/

SET NAMES utf8mb4;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS=0;
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS;
SET UNIQUE_CHECKS=0;

CREATE DATABASE IF NOT EXISTS `modunexa`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `modunexa`;

-- =========================================================
-- PLATAFORMA / TENANCY / SEGURANÇA
-- =========================================================

DROP TABLE IF EXISTS `auditoria_eventos`;
DROP TABLE IF EXISTS `outbox_eventos`;
DROP TABLE IF EXISTS `notificacoes`;
DROP TABLE IF EXISTS `ia_feedback`;
DROP TABLE IF EXISTS `ia_fontes_resposta`;
DROP TABLE IF EXISTS `ia_execucoes`;
DROP TABLE IF EXISTS `ia_mensagens`;
DROP TABLE IF EXISTS `ia_conversas`;
DROP TABLE IF EXISTS `ia_assistentes`;
DROP TABLE IF EXISTS `documento_chunks`;
DROP TABLE IF EXISTS `documento_paginas`;
DROP TABLE IF EXISTS `documentos`;
DROP TABLE IF EXISTS `importacao_linhas`;
DROP TABLE IF EXISTS `importacoes`;
DROP TABLE IF EXISTS `arquivos`;
DROP TABLE IF EXISTS `agenda_eventos`;
DROP TABLE IF EXISTS `producao_movimentacoes`;
DROP TABLE IF EXISTS `producao_ordens`;
DROP TABLE IF EXISTS `producao_etapas`;
DROP TABLE IF EXISTS `crm_historico_etapas`;
DROP TABLE IF EXISTS `crm_oportunidades`;
DROP TABLE IF EXISTS `crm_etapas`;
DROP TABLE IF EXISTS `crm_funis`;
DROP TABLE IF EXISTS `contrato_aditivos`;
DROP TABLE IF EXISTS `contrato_assinaturas`;
DROP TABLE IF EXISTS `contrato_parcelas`;
DROP TABLE IF EXISTS `contrato_prazos`;
DROP TABLE IF EXISTS `contrato_versoes`;
DROP TABLE IF EXISTS `contratos`;
DROP TABLE IF EXISTS `orcamento_status_historico`;
DROP TABLE IF EXISTS `orcamento_versoes`;
DROP TABLE IF EXISTS `orcamento_ajustes`;
DROP TABLE IF EXISTS `orcamento_itens`;
DROP TABLE IF EXISTS `orcamento_ambientes`;
DROP TABLE IF EXISTS `orcamentos`;
DROP TABLE IF EXISTS `precos_itens`;
DROP TABLE IF EXISTS `itens_catalogo`;
DROP TABLE IF EXISTS `categorias`;
DROP TABLE IF EXISTS `ambiente_especificacoes`;
DROP TABLE IF EXISTS `ambientes`;
DROP TABLE IF EXISTS `catalogo_modelo_itens`;
DROP TABLE IF EXISTS `catalogo_modelo_categorias`;
DROP TABLE IF EXISTS `ambiente_modelo_especificacoes`;
DROP TABLE IF EXISTS `ambientes_modelo`;
DROP TABLE IF EXISTS `regras_negocio`;
DROP TABLE IF EXISTS `marcenaria_fornecedores`;
DROP TABLE IF EXISTS `fornecedores`;
DROP TABLE IF EXISTS `clientes`;
DROP TABLE IF EXISTS `parceiros`;
DROP TABLE IF EXISTS `colaboradores`;
DROP TABLE IF EXISTS `lojas`;
DROP TABLE IF EXISTS `usuario_perfis`;
DROP TABLE IF EXISTS `perfis`;
DROP TABLE IF EXISTS `sessoes_usuario`;
DROP TABLE IF EXISTS `usuarios`;
DROP TABLE IF EXISTS `marcenarias`;
DROP TABLE IF EXISTS `plataforma_config`;
DROP TABLE IF EXISTS `__efmigrationshistory`;

CREATE TABLE `__efmigrationshistory` (
  `MigrationId` varchar(150) NOT NULL,
  `ProductVersion` varchar(32) NOT NULL,
  PRIMARY KEY (`MigrationId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `plataforma_config` (
  `id` tinyint unsigned NOT NULL DEFAULT 1,
  `nome_plataforma` varchar(100) NOT NULL DEFAULT 'ModuNexa',
  `versao_schema` varchar(30) NOT NULL DEFAULT '2.0.0',
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_plataforma_config_unico` CHECK (`id` = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `marcenarias` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `tipo_pessoa` varchar(2) NOT NULL DEFAULT 'PJ',
  `nome_fantasia` varchar(180) NOT NULL,
  `razao_social` varchar(255) DEFAULT NULL,
  `cpf_cnpj` varchar(20) DEFAULT NULL,
  `inscricao_estadual` varchar(30) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `site` varchar(255) DEFAULT NULL,
  `cep` varchar(12) DEFAULT NULL,
  `logradouro` varchar(255) DEFAULT NULL,
  `numero` varchar(30) DEFAULT NULL,
  `complemento` varchar(120) DEFAULT NULL,
  `bairro` varchar(120) DEFAULT NULL,
  `cidade` varchar(120) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `logo_arquivo_id` bigint unsigned DEFAULT NULL,
  `texto_cabecalho_orcamento` text DEFAULT NULL,
  `texto_rodape_orcamento` text DEFAULT NULL,
  `plano` varchar(30) NOT NULL DEFAULT 'BASIC',
  `status` varchar(30) NOT NULL DEFAULT 'ATIVA',
  `timezone` varchar(60) NOT NULL DEFAULT 'America/Sao_Paulo',
  `moeda` char(3) NOT NULL DEFAULT 'BRL',
  `configuracoes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`configuracoes`)),
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_marcenarias_public_id` (`public_id`),
  UNIQUE KEY `uk_marcenarias_cpf_cnpj` (`cpf_cnpj`),
  KEY `idx_marcenarias_nome` (`nome_fantasia`),
  KEY `idx_marcenarias_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `usuarios` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = usuário administrativo da plataforma ModuNexa',
  `nome` varchar(180) NOT NULL,
  `email` varchar(255) NOT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `senha_hash` varchar(255) DEFAULT NULL,
  `provedor_login` varchar(30) NOT NULL DEFAULT 'LOCAL',
  `provedor_subject` varchar(255) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'ATIVO',
  `email_confirmado_em` datetime(6) DEFAULT NULL,
  `ultimo_acesso_em` datetime(6) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_usuarios_public_id` (`public_id`),
  UNIQUE KEY `uk_usuarios_email_tenant` (`marcenaria_id`,`email`),
  KEY `idx_usuarios_email` (`email`),
  KEY `idx_usuarios_tenant_status` (`marcenaria_id`,`status`),
  CONSTRAINT `fk_usuarios_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sessoes_usuario` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `refresh_token_hash` char(64) NOT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `expira_em` datetime(6) NOT NULL,
  `revogado_em` datetime(6) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sessoes_refresh_hash` (`refresh_token_hash`),
  KEY `idx_sessoes_usuario_expira` (`usuario_id`,`expira_em`),
  CONSTRAINT `fk_sessoes_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `perfis` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `escopo` varchar(20) NOT NULL DEFAULT 'MARCENARIA',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_perfis_codigo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `usuario_perfis` (
  `usuario_id` bigint unsigned NOT NULL,
  `perfil_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`usuario_id`,`perfil_id`),
  CONSTRAINT `fk_usuario_perfis_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_usuario_perfis_perfil` FOREIGN KEY (`perfil_id`) REFERENCES `perfis` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- CADASTROS DE NEGÓCIO
-- =========================================================

CREATE TABLE `lojas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `nome` varchar(180) NOT NULL,
  `razao_social` varchar(255) DEFAULT NULL,
  `cnpj` varchar(20) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `cep` varchar(12) DEFAULT NULL,
  `logradouro` varchar(255) DEFAULT NULL,
  `numero` varchar(30) DEFAULT NULL,
  `complemento` varchar(120) DEFAULT NULL,
  `bairro` varchar(120) DEFAULT NULL,
  `cidade` varchar(120) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `ativa` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_lojas_public_id` (`public_id`),
  UNIQUE KEY `uk_lojas_tenant_nome` (`marcenaria_id`,`nome`),
  KEY `idx_lojas_tenant_cidade` (`marcenaria_id`,`cidade`),
  CONSTRAINT `fk_lojas_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `colaboradores` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `loja_id` bigint unsigned DEFAULT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `nome` varchar(180) NOT NULL,
  `cargo` varchar(30) NOT NULL COMMENT 'VENDEDOR, PROJETISTA, MEDIDOR, MONTADOR, ADMIN...',
  `cpf` varchar(20) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_colaboradores_public_id` (`public_id`),
  KEY `idx_colaboradores_tenant_cargo` (`marcenaria_id`,`cargo`,`ativo`),
  KEY `idx_colaboradores_loja` (`loja_id`),
  CONSTRAINT `fk_colaboradores_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_colaboradores_lojas` FOREIGN KEY (`loja_id`) REFERENCES `lojas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_colaboradores_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `parceiros` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `tipo` varchar(30) NOT NULL COMMENT 'ARQUITETO, DESIGNER, INDICADOR, INSTALADOR, OUTRO',
  `nome` varchar(180) NOT NULL,
  `cpf_cnpj` varchar(20) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `data_nascimento` date DEFAULT NULL,
  `cidade` varchar(120) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `chave_pix` varchar(255) DEFAULT NULL,
  `observacoes` text DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_parceiros_public_id` (`public_id`),
  KEY `idx_parceiros_tenant_tipo_nome` (`marcenaria_id`,`tipo`,`nome`),
  CONSTRAINT `fk_parceiros_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `clientes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `loja_id` bigint unsigned DEFAULT NULL,
  `nome` varchar(180) NOT NULL,
  `tipo_pessoa` varchar(2) NOT NULL DEFAULT 'PF',
  `cpf_cnpj` varchar(20) DEFAULT NULL,
  `rg_ie` varchar(30) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `whatsapp` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `data_nascimento` date DEFAULT NULL,
  `cep` varchar(12) DEFAULT NULL,
  `logradouro` varchar(255) DEFAULT NULL,
  `numero` varchar(30) DEFAULT NULL,
  `complemento` varchar(120) DEFAULT NULL,
  `bairro` varchar(120) DEFAULT NULL,
  `cidade` varchar(120) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `origem_lead` varchar(80) DEFAULT NULL,
  `observacoes` text DEFAULT NULL,
  `consentimento_lgpd_em` datetime(6) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_clientes_public_id` (`public_id`),
  KEY `idx_clientes_tenant_nome` (`marcenaria_id`,`nome`),
  KEY `idx_clientes_tenant_cpf_cnpj` (`marcenaria_id`,`cpf_cnpj`),
  KEY `idx_clientes_tenant_cidade` (`marcenaria_id`,`cidade`),
  KEY `idx_clientes_tenant_nascimento` (`marcenaria_id`,`data_nascimento`),
  CONSTRAINT `fk_clientes_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_clientes_lojas` FOREIGN KEY (`loja_id`) REFERENCES `lojas` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `fornecedores` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `nome` varchar(180) NOT NULL,
  `razao_social` varchar(255) DEFAULT NULL,
  `cnpj` varchar(20) DEFAULT NULL,
  `telefone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `site` varchar(255) DEFAULT NULL,
  `cidade` varchar(120) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fornecedores_public_id` (`public_id`),
  UNIQUE KEY `uk_fornecedores_cnpj` (`cnpj`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `marcenaria_fornecedores` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `fornecedor_id` bigint unsigned NOT NULL,
  `codigo_cliente` varchar(80) DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `configuracoes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`configuracoes`)),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_marcenaria_fornecedor` (`marcenaria_id`,`fornecedor_id`),
  CONSTRAINT `fk_mf_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mf_fornecedores` FOREIGN KEY (`fornecedor_id`) REFERENCES `fornecedores` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `regras_negocio` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `codigo` varchar(100) NOT NULL,
  `nome` varchar(180) NOT NULL,
  `descricao` text NOT NULL,
  `regra_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`regra_json`)),
  `versao` int unsigned NOT NULL DEFAULT 1,
  `ativa` tinyint(1) NOT NULL DEFAULT 1,
  `vigente_de` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `vigente_ate` datetime(6) DEFAULT NULL,
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_regras_tenant_codigo_versao` (`marcenaria_id`,`codigo`,`versao`),
  KEY `idx_regras_tenant_ativas` (`marcenaria_id`,`ativa`,`codigo`),
  CONSTRAINT `fk_regras_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_regras_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- MODELOS GLOBAIS PARA IMPLANTAÇÃO / IMPORTAÇÃO
-- =========================================================

CREATE TABLE `ambientes_modelo` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nome` varchar(180) NOT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ambientes_modelo_nome` (`nome`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ambiente_modelo_especificacoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ambiente_modelo_id` bigint unsigned NOT NULL,
  `descricao` varchar(255) NOT NULL,
  `ordem` smallint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_amb_modelo_espec` (`ambiente_modelo_id`,`descricao`),
  CONSTRAINT `fk_amb_modelo_espec` FOREIGN KEY (`ambiente_modelo_id`) REFERENCES `ambientes_modelo` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `catalogo_modelo_categorias` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nome` varchar(180) NOT NULL,
  `tipo_calculo` varchar(30) NOT NULL COMMENT 'AREA, QUANTIDADE, COMPRIMENTO, MATERIAL_MARKUP, VALOR_FIXO, PERSONALIZADO',
  `unidade_padrao` varchar(20) NOT NULL DEFAULT 'un',
  `formula_legada` varchar(255) DEFAULT NULL COMMENT 'Somente referência/migração; não executar diretamente',
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_catalogo_modelo_categoria_nome` (`nome`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `catalogo_modelo_itens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `categoria_modelo_id` bigint unsigned NOT NULL,
  `descricao` varchar(255) NOT NULL,
  `altura_padrao` decimal(12,4) DEFAULT NULL,
  `observacao` varchar(500) DEFAULT NULL,
  `markup_percentual` decimal(9,4) NOT NULL DEFAULT 0,
  `preco_base` decimal(18,4) NOT NULL DEFAULT 0,
  `parametros` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`parametros`)),
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_catalogo_modelo_item` (`categoria_modelo_id`,`descricao`),
  CONSTRAINT `fk_catalogo_modelo_itens_categoria` FOREIGN KEY (`categoria_modelo_id`) REFERENCES `catalogo_modelo_categorias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- CATÁLOGO DA MARCENARIA
-- =========================================================

CREATE TABLE `ambientes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `nome` varchar(180) NOT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ambientes_public_id` (`public_id`),
  UNIQUE KEY `uk_ambientes_tenant_nome` (`marcenaria_id`,`nome`),
  CONSTRAINT `fk_ambientes_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ambiente_especificacoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ambiente_id` bigint unsigned NOT NULL,
  `descricao` varchar(255) NOT NULL,
  `ordem` smallint unsigned NOT NULL DEFAULT 0,
  `ativa` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ambiente_especificacao` (`ambiente_id`,`descricao`),
  CONSTRAINT `fk_ambiente_especificacoes` FOREIGN KEY (`ambiente_id`) REFERENCES `ambientes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `categorias` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `nome` varchar(180) NOT NULL,
  `tipo_calculo` varchar(30) NOT NULL COMMENT 'AREA, QUANTIDADE, COMPRIMENTO, MATERIAL_MARKUP, VALOR_FIXO, PERSONALIZADO',
  `unidade_padrao` varchar(20) NOT NULL DEFAULT 'un',
  `parametros_calculo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`parametros_calculo`)),
  `ordem` smallint unsigned NOT NULL DEFAULT 0,
  `ativa` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_categorias_public_id` (`public_id`),
  UNIQUE KEY `uk_categorias_tenant_nome` (`marcenaria_id`,`nome`),
  KEY `idx_categorias_tenant_ativas` (`marcenaria_id`,`ativa`,`ordem`),
  CONSTRAINT `fk_categorias_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `itens_catalogo` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `categoria_id` bigint unsigned NOT NULL,
  `codigo` varchar(80) DEFAULT NULL,
  `descricao` varchar(255) NOT NULL,
  `altura_padrao` decimal(12,4) DEFAULT NULL,
  `observacao` varchar(500) DEFAULT NULL,
  `markup_percentual` decimal(9,4) NOT NULL DEFAULT 0,
  `parametros` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`parametros`)),
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_itens_catalogo_public_id` (`public_id`),
  UNIQUE KEY `uk_itens_catalogo_tenant_categoria_desc` (`marcenaria_id`,`categoria_id`,`descricao`),
  KEY `idx_itens_catalogo_tenant_ativo` (`marcenaria_id`,`ativo`,`categoria_id`),
  CONSTRAINT `fk_itens_catalogo_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_itens_catalogo_categorias` FOREIGN KEY (`categoria_id`) REFERENCES `categorias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `precos_itens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `item_catalogo_id` bigint unsigned NOT NULL,
  `fornecedor_id` bigint unsigned DEFAULT NULL,
  `preco_custo` decimal(18,4) DEFAULT NULL,
  `preco_venda` decimal(18,4) NOT NULL,
  `markup_percentual` decimal(9,4) DEFAULT NULL,
  `vigente_de` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `vigente_ate` datetime(6) DEFAULT NULL,
  `origem` varchar(30) NOT NULL DEFAULT 'MANUAL' COMMENT 'MANUAL, PLANILHA, FORNECEDOR, IA',
  `importacao_id` bigint unsigned DEFAULT NULL,
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_precos_item_vigencia` (`item_catalogo_id`,`vigente_de`,`vigente_ate`),
  KEY `idx_precos_tenant_vigencia` (`marcenaria_id`,`vigente_de`),
  CONSTRAINT `fk_precos_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_precos_itens` FOREIGN KEY (`item_catalogo_id`) REFERENCES `itens_catalogo` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_precos_fornecedores` FOREIGN KEY (`fornecedor_id`) REFERENCES `fornecedores` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_precos_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- ORÇAMENTOS
-- =========================================================

CREATE TABLE `orcamentos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `loja_id` bigint unsigned DEFAULT NULL,
  `cliente_id` bigint unsigned NOT NULL,
  `vendedor_id` bigint unsigned DEFAULT NULL,
  `arquiteto_id` bigint unsigned DEFAULT NULL,
  `numero` bigint unsigned NOT NULL,
  `versao_atual` int unsigned NOT NULL DEFAULT 1,
  `status` varchar(30) NOT NULL DEFAULT 'RASCUNHO',
  `data_orcamento` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `validade_ate` date DEFAULT NULL,
  `subtotal` decimal(18,2) NOT NULL DEFAULT 0,
  `total_acrescimos` decimal(18,2) NOT NULL DEFAULT 0,
  `total_descontos` decimal(18,2) NOT NULL DEFAULT 0,
  `total` decimal(18,2) NOT NULL DEFAULT 0,
  `texto_cabecalho` text DEFAULT NULL,
  `texto_rodape` text DEFAULT NULL,
  `observacoes_internas` text DEFAULT NULL,
  `observacoes_cliente` text DEFAULT NULL,
  `metadados` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadados`)),
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orcamentos_public_id` (`public_id`),
  UNIQUE KEY `uk_orcamentos_tenant_numero` (`marcenaria_id`,`numero`),
  KEY `idx_orcamentos_dashboard` (`marcenaria_id`,`status`,`data_orcamento`),
  KEY `idx_orcamentos_cliente_data` (`marcenaria_id`,`cliente_id`,`data_orcamento`),
  CONSTRAINT `fk_orcamentos_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`),
  CONSTRAINT `fk_orcamentos_lojas` FOREIGN KEY (`loja_id`) REFERENCES `lojas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_orcamentos_clientes` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`),
  CONSTRAINT `fk_orcamentos_vendedores` FOREIGN KEY (`vendedor_id`) REFERENCES `colaboradores` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_orcamentos_arquitetos` FOREIGN KEY (`arquiteto_id`) REFERENCES `parceiros` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_orcamentos_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orcamento_ambientes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `orcamento_id` bigint unsigned NOT NULL,
  `ambiente_id` bigint unsigned DEFAULT NULL,
  `nome_ambiente` varchar(180) NOT NULL COMMENT 'snapshot: mantém o nome mesmo se cadastro mudar',
  `descricao` text DEFAULT NULL,
  `ordem` smallint unsigned NOT NULL DEFAULT 0,
  `subtotal` decimal(18,2) NOT NULL DEFAULT 0,
  `total` decimal(18,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orc_amb_public_id` (`public_id`),
  KEY `idx_orc_amb_orcamento_ordem` (`orcamento_id`,`ordem`),
  CONSTRAINT `fk_orc_amb_orcamentos` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orc_amb_ambientes` FOREIGN KEY (`ambiente_id`) REFERENCES `ambientes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orcamento_itens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `orcamento_ambiente_id` bigint unsigned NOT NULL,
  `item_catalogo_id` bigint unsigned DEFAULT NULL,
  `categoria_nome` varchar(180) NOT NULL,
  `item_descricao` varchar(255) NOT NULL,
  `tipo_calculo` varchar(30) NOT NULL,
  `unidade` varchar(20) NOT NULL,
  `largura` decimal(12,4) DEFAULT NULL,
  `altura` decimal(12,4) DEFAULT NULL,
  `profundidade` decimal(12,4) DEFAULT NULL,
  `comprimento` decimal(12,4) DEFAULT NULL,
  `quantidade` decimal(12,4) NOT NULL DEFAULT 1,
  `preco_base` decimal(18,4) NOT NULL DEFAULT 0,
  `custo_base` decimal(18,4) DEFAULT NULL,
  `markup_percentual` decimal(9,4) NOT NULL DEFAULT 0,
  `parametros_entrada` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`parametros_entrada`)),
  `memoria_calculo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`memoria_calculo`)),
  `valor_unitario_calculado` decimal(18,4) NOT NULL DEFAULT 0,
  `valor_total` decimal(18,2) NOT NULL DEFAULT 0,
  `observacao` text DEFAULT NULL,
  `ordem` smallint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orc_itens_public_id` (`public_id`),
  KEY `idx_orc_itens_ambiente_ordem` (`orcamento_ambiente_id`,`ordem`),
  KEY `idx_orc_itens_catalogo` (`item_catalogo_id`),
  CONSTRAINT `fk_orc_itens_ambiente` FOREIGN KEY (`orcamento_ambiente_id`) REFERENCES `orcamento_ambientes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orc_itens_catalogo` FOREIGN KEY (`item_catalogo_id`) REFERENCES `itens_catalogo` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orcamento_ajustes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `orcamento_id` bigint unsigned NOT NULL,
  `tipo` varchar(30) NOT NULL COMMENT 'DESCONTO, ACRESCIMO, RT, FRETE, TAXA, OUTRO',
  `descricao` varchar(255) DEFAULT NULL,
  `modo` varchar(20) NOT NULL DEFAULT 'PERCENTUAL' COMMENT 'PERCENTUAL ou VALOR',
  `percentual` decimal(9,4) DEFAULT NULL,
  `valor` decimal(18,2) DEFAULT NULL,
  `base_calculo` decimal(18,2) DEFAULT NULL,
  `valor_calculado` decimal(18,2) NOT NULL DEFAULT 0,
  `parceiro_id` bigint unsigned DEFAULT NULL,
  `ordem` smallint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_orc_ajustes_orcamento` (`orcamento_id`,`tipo`),
  CONSTRAINT `fk_orc_ajustes_orcamento` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orc_ajustes_parceiro` FOREIGN KEY (`parceiro_id`) REFERENCES `parceiros` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orcamento_versoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `orcamento_id` bigint unsigned NOT NULL,
  `versao` int unsigned NOT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `snapshot_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`snapshot_json`)),
  `hash_snapshot` char(64) DEFAULT NULL,
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orc_versoes` (`orcamento_id`,`versao`),
  CONSTRAINT `fk_orc_versoes_orcamento` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orc_versoes_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orcamento_status_historico` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `orcamento_id` bigint unsigned NOT NULL,
  `status_anterior` varchar(30) DEFAULT NULL,
  `status_novo` varchar(30) NOT NULL,
  `motivo` varchar(500) DEFAULT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `ocorrido_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_orc_status_orcamento_data` (`orcamento_id`,`ocorrido_em`),
  CONSTRAINT `fk_orc_status_orcamento` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orc_status_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- CONTRATOS / PAGAMENTOS / ADITIVOS
-- =========================================================

CREATE TABLE `contratos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `orcamento_id` bigint unsigned NOT NULL,
  `cliente_id` bigint unsigned NOT NULL,
  `vendedor_id` bigint unsigned DEFAULT NULL,
  `arquiteto_id` bigint unsigned DEFAULT NULL,
  `numero` bigint unsigned NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'RASCUNHO',
  `valor_contrato` decimal(18,2) NOT NULL,
  `forma_pagamento_descricao` text DEFAULT NULL,
  `data_assinatura` datetime(6) DEFAULT NULL,
  `data_cancelamento` datetime(6) DEFAULT NULL,
  `motivo_cancelamento` text DEFAULT NULL,
  `versao_atual` int unsigned NOT NULL DEFAULT 1,
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_contratos_public_id` (`public_id`),
  UNIQUE KEY `uk_contratos_tenant_numero` (`marcenaria_id`,`numero`),
  KEY `idx_contratos_tenant_status` (`marcenaria_id`,`status`,`data_assinatura`),
  KEY `idx_contratos_orcamento` (`orcamento_id`),
  CONSTRAINT `fk_contratos_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`),
  CONSTRAINT `fk_contratos_orcamentos` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`),
  CONSTRAINT `fk_contratos_clientes` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`),
  CONSTRAINT `fk_contratos_vendedores` FOREIGN KEY (`vendedor_id`) REFERENCES `colaboradores` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_contratos_arquitetos` FOREIGN KEY (`arquiteto_id`) REFERENCES `parceiros` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_contratos_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contrato_versoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `contrato_id` bigint unsigned NOT NULL,
  `versao` int unsigned NOT NULL,
  `conteudo_html` longtext DEFAULT NULL,
  `snapshot_dados` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`snapshot_dados`)),
  `arquivo_pdf_id` bigint unsigned DEFAULT NULL COMMENT 'FK adicionada logicamente após geração do documento; arquivos são genéricos',
  `hash_documento` char(64) DEFAULT NULL,
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_contrato_versoes` (`contrato_id`,`versao`),
  CONSTRAINT `fk_contrato_versoes_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_contrato_versoes_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contrato_prazos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `contrato_id` bigint unsigned NOT NULL,
  `tipo` varchar(50) NOT NULL COMMENT 'MEDICAO, PROJETO_APROVACAO, APROVACAO_CLIENTE, ENTREGA, INICIO_MONTAGEM, GARANTIA_MADEIRA, GARANTIA_FERRAGENS...',
  `data_base` date DEFAULT NULL,
  `quantidade` int DEFAULT NULL,
  `unidade` varchar(20) DEFAULT NULL COMMENT 'DIAS_CORRIDOS, DIAS_UTEIS, MESES, ANOS',
  `data_prevista` date DEFAULT NULL,
  `data_realizada` date DEFAULT NULL,
  `suspenso_em` datetime(6) DEFAULT NULL,
  `motivo_suspensao` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_contrato_prazo_tipo` (`contrato_id`,`tipo`),
  KEY `idx_contrato_prazos_prevista` (`data_prevista`,`tipo`),
  CONSTRAINT `fk_contrato_prazos_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contrato_parcelas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `contrato_id` bigint unsigned NOT NULL,
  `numero_parcela` smallint unsigned NOT NULL,
  `forma_pagamento` varchar(40) DEFAULT NULL,
  `valor` decimal(18,2) NOT NULL,
  `vencimento_em` date DEFAULT NULL,
  `pago_em` datetime(6) DEFAULT NULL,
  `valor_pago` decimal(18,2) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'PENDENTE',
  `referencia_externa` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_contrato_parcela` (`contrato_id`,`numero_parcela`),
  KEY `idx_parcelas_vencimento_status` (`vencimento_em`,`status`),
  CONSTRAINT `fk_contrato_parcelas_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contrato_assinaturas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `contrato_id` bigint unsigned NOT NULL,
  `papel` varchar(30) NOT NULL COMMENT 'CONTRATANTE, CONTRATADA, TESTEMUNHA, AVALISTA',
  `nome` varchar(180) NOT NULL,
  `cpf` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `provedor` varchar(50) DEFAULT NULL,
  `envelope_id` varchar(255) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'PENDENTE',
  `assinado_em` datetime(6) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_assinaturas_contrato_status` (`contrato_id`,`status`),
  CONSTRAINT `fk_contrato_assinaturas_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contrato_aditivos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `contrato_id` bigint unsigned NOT NULL,
  `numero` smallint unsigned NOT NULL,
  `descricao` text NOT NULL,
  `valor_diferenca` decimal(18,2) NOT NULL DEFAULT 0,
  `dias_acrescimo_prazo` int NOT NULL DEFAULT 0,
  `status` varchar(30) NOT NULL DEFAULT 'RASCUNHO',
  `assinatura_em` datetime(6) DEFAULT NULL,
  `snapshot_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`snapshot_json`)),
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_aditivos_public_id` (`public_id`),
  UNIQUE KEY `uk_aditivos_contrato_numero` (`contrato_id`,`numero`),
  CONSTRAINT `fk_aditivos_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- CRM / PRODUÇÃO / CRONOGRAMA
-- =========================================================

CREATE TABLE `crm_funis` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `nome` varchar(120) NOT NULL,
  `tipo` varchar(30) NOT NULL DEFAULT 'COMERCIAL',
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crm_funil` (`marcenaria_id`,`tipo`,`nome`),
  CONSTRAINT `fk_crm_funis_marcenarias` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `crm_etapas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `funil_id` bigint unsigned NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nome` varchar(120) NOT NULL,
  `ordem` smallint unsigned NOT NULL,
  `tipo_final` varchar(20) DEFAULT NULL COMMENT 'GANHO, PERDIDO ou NULL',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crm_etapa_codigo` (`funil_id`,`codigo`),
  UNIQUE KEY `uk_crm_etapa_ordem` (`funil_id`,`ordem`),
  CONSTRAINT `fk_crm_etapas_funil` FOREIGN KEY (`funil_id`) REFERENCES `crm_funis` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `crm_oportunidades` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `cliente_id` bigint unsigned NOT NULL,
  `orcamento_id` bigint unsigned DEFAULT NULL,
  `funil_id` bigint unsigned NOT NULL,
  `etapa_id` bigint unsigned NOT NULL,
  `responsavel_id` bigint unsigned DEFAULT NULL,
  `titulo` varchar(255) NOT NULL,
  `valor_estimado` decimal(18,2) DEFAULT NULL,
  `proxima_acao_em` datetime(6) DEFAULT NULL,
  `motivo_perda` varchar(500) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crm_oportunidades_public_id` (`public_id`),
  KEY `idx_crm_kanban` (`marcenaria_id`,`funil_id`,`etapa_id`,`proxima_acao_em`),
  CONSTRAINT `fk_crm_oportunidades_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_crm_oportunidades_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`),
  CONSTRAINT `fk_crm_oportunidades_orcamento` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crm_oportunidades_funil` FOREIGN KEY (`funil_id`) REFERENCES `crm_funis` (`id`),
  CONSTRAINT `fk_crm_oportunidades_etapa` FOREIGN KEY (`etapa_id`) REFERENCES `crm_etapas` (`id`),
  CONSTRAINT `fk_crm_oportunidades_responsavel` FOREIGN KEY (`responsavel_id`) REFERENCES `colaboradores` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `crm_historico_etapas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `oportunidade_id` bigint unsigned NOT NULL,
  `etapa_anterior_id` bigint unsigned DEFAULT NULL,
  `etapa_nova_id` bigint unsigned NOT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `observacao` varchar(500) DEFAULT NULL,
  `ocorrido_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_crm_hist_oportunidade` (`oportunidade_id`,`ocorrido_em`),
  CONSTRAINT `fk_crm_hist_oportunidade` FOREIGN KEY (`oportunidade_id`) REFERENCES `crm_oportunidades` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_crm_hist_etapa_anterior` FOREIGN KEY (`etapa_anterior_id`) REFERENCES `crm_etapas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crm_hist_etapa_nova` FOREIGN KEY (`etapa_nova_id`) REFERENCES `crm_etapas` (`id`),
  CONSTRAINT `fk_crm_hist_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `producao_etapas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `nome` varchar(120) NOT NULL,
  `ordem` smallint unsigned NOT NULL,
  `ativa` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_producao_etapa_codigo` (`marcenaria_id`,`codigo`),
  UNIQUE KEY `uk_producao_etapa_ordem` (`marcenaria_id`,`ordem`),
  CONSTRAINT `fk_producao_etapas_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `producao_ordens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `contrato_id` bigint unsigned NOT NULL,
  `etapa_atual_id` bigint unsigned NOT NULL,
  `responsavel_id` bigint unsigned DEFAULT NULL,
  `prioridade` varchar(20) NOT NULL DEFAULT 'NORMAL',
  `inicio_previsto` date DEFAULT NULL,
  `entrega_prevista` date DEFAULT NULL,
  `inicio_real` datetime(6) DEFAULT NULL,
  `fim_real` datetime(6) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'ABERTA',
  `observacoes` text DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_producao_ordens_public_id` (`public_id`),
  UNIQUE KEY `uk_producao_ordens_contrato` (`contrato_id`),
  KEY `idx_producao_kanban` (`marcenaria_id`,`etapa_atual_id`,`prioridade`,`entrega_prevista`),
  CONSTRAINT `fk_producao_ordens_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_producao_ordens_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`),
  CONSTRAINT `fk_producao_ordens_etapa` FOREIGN KEY (`etapa_atual_id`) REFERENCES `producao_etapas` (`id`),
  CONSTRAINT `fk_producao_ordens_responsavel` FOREIGN KEY (`responsavel_id`) REFERENCES `colaboradores` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `producao_movimentacoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ordem_producao_id` bigint unsigned NOT NULL,
  `etapa_anterior_id` bigint unsigned DEFAULT NULL,
  `etapa_nova_id` bigint unsigned NOT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `observacao` varchar(500) DEFAULT NULL,
  `ocorrido_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_prod_mov_ordem_data` (`ordem_producao_id`,`ocorrido_em`),
  CONSTRAINT `fk_prod_mov_ordem` FOREIGN KEY (`ordem_producao_id`) REFERENCES `producao_ordens` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_prod_mov_etapa_ant` FOREIGN KEY (`etapa_anterior_id`) REFERENCES `producao_etapas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_prod_mov_etapa_nova` FOREIGN KEY (`etapa_nova_id`) REFERENCES `producao_etapas` (`id`),
  CONSTRAINT `fk_prod_mov_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `agenda_eventos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `tipo` varchar(40) NOT NULL COMMENT 'MEDICAO, APROVACAO, ENTREGA, MONTAGEM, ASSISTENCIA, RETORNO_COMERCIAL, OUTRO',
  `titulo` varchar(255) NOT NULL,
  `inicio_em` datetime(6) NOT NULL,
  `fim_em` datetime(6) DEFAULT NULL,
  `dia_inteiro` tinyint(1) NOT NULL DEFAULT 0,
  `cliente_id` bigint unsigned DEFAULT NULL,
  `orcamento_id` bigint unsigned DEFAULT NULL,
  `contrato_id` bigint unsigned DEFAULT NULL,
  `ordem_producao_id` bigint unsigned DEFAULT NULL,
  `responsavel_id` bigint unsigned DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'AGENDADO',
  `observacoes` text DEFAULT NULL,
  `metadados` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadados`)),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agenda_public_id` (`public_id`),
  KEY `idx_agenda_tenant_inicio` (`marcenaria_id`,`inicio_em`,`tipo`),
  CONSTRAINT `fk_agenda_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_agenda_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_agenda_orcamento` FOREIGN KEY (`orcamento_id`) REFERENCES `orcamentos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_agenda_contrato` FOREIGN KEY (`contrato_id`) REFERENCES `contratos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_agenda_producao` FOREIGN KEY (`ordem_producao_id`) REFERENCES `producao_ordens` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_agenda_responsavel` FOREIGN KEY (`responsavel_id`) REFERENCES `colaboradores` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- ARQUIVOS, PLANILHAS, PDF E BASE DE CONHECIMENTO
-- =========================================================

CREATE TABLE `arquivos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = arquivo global da plataforma',
  `nome_original` varchar(255) NOT NULL,
  `nome_storage` varchar(255) DEFAULT NULL,
  `mime_type` varchar(120) NOT NULL,
  `extensao` varchar(20) DEFAULT NULL,
  `tamanho_bytes` bigint unsigned DEFAULT NULL,
  `sha256` char(64) DEFAULT NULL,
  `storage_provider` varchar(30) NOT NULL DEFAULT 'S3',
  `storage_uri` varchar(1000) NOT NULL,
  `status_antivirus` varchar(30) NOT NULL DEFAULT 'PENDENTE',
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_arquivos_public_id` (`public_id`),
  KEY `idx_arquivos_tenant_data` (`marcenaria_id`,`criado_em`),
  KEY `idx_arquivos_sha256` (`sha256`),
  CONSTRAINT `fk_arquivos_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_arquivos_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `marcenarias`
  ADD CONSTRAINT `fk_marcenarias_logo_arquivo` FOREIGN KEY (`logo_arquivo_id`) REFERENCES `arquivos` (`id`) ON DELETE SET NULL;

CREATE TABLE `importacoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `arquivo_id` bigint unsigned NOT NULL,
  `tipo` varchar(40) NOT NULL COMMENT 'AMBIENTES, CATEGORIAS, ITENS_CATALOGO, PRECOS, CLIENTES, OUTRO',
  `status` varchar(30) NOT NULL DEFAULT 'PENDENTE',
  `mapeamento_colunas` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`mapeamento_colunas`)),
  `total_linhas` int unsigned NOT NULL DEFAULT 0,
  `linhas_sucesso` int unsigned NOT NULL DEFAULT 0,
  `linhas_erro` int unsigned NOT NULL DEFAULT 0,
  `resumo` text DEFAULT NULL,
  `iniciado_em` datetime(6) DEFAULT NULL,
  `finalizado_em` datetime(6) DEFAULT NULL,
  `criado_por_usuario_id` bigint unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_importacoes_public_id` (`public_id`),
  KEY `idx_importacoes_tenant_status` (`marcenaria_id`,`status`,`criado_em`),
  CONSTRAINT `fk_importacoes_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_importacoes_arquivo` FOREIGN KEY (`arquivo_id`) REFERENCES `arquivos` (`id`),
  CONSTRAINT `fk_importacoes_usuario` FOREIGN KEY (`criado_por_usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `precos_itens`
  ADD CONSTRAINT `fk_precos_importacao` FOREIGN KEY (`importacao_id`) REFERENCES `importacoes` (`id`) ON DELETE SET NULL;

CREATE TABLE `importacao_linhas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `importacao_id` bigint unsigned NOT NULL,
  `numero_linha` int unsigned NOT NULL,
  `dados_originais` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`dados_originais`)),
  `dados_normalizados` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`dados_normalizados`)),
  `status` varchar(20) NOT NULL DEFAULT 'PENDENTE',
  `erro_codigo` varchar(80) DEFAULT NULL,
  `erro_mensagem` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_importacao_linha` (`importacao_id`,`numero_linha`),
  KEY `idx_importacao_linhas_status` (`importacao_id`,`status`),
  CONSTRAINT `fk_importacao_linhas_importacao` FOREIGN KEY (`importacao_id`) REFERENCES `importacoes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `documentos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `arquivo_id` bigint unsigned NOT NULL,
  `tipo` varchar(40) NOT NULL COMMENT 'CONTRATO, ORCAMENTO, PROJETO, MANUAL, TABELA_PRECO, NOTA, OUTRO',
  `titulo` varchar(255) NOT NULL,
  `entidade_tipo` varchar(40) DEFAULT NULL COMMENT 'CLIENTE, ORCAMENTO, CONTRATO, PRODUCAO...',
  `entidade_id` bigint unsigned DEFAULT NULL,
  `versao` int unsigned NOT NULL DEFAULT 1,
  `status_processamento` varchar(30) NOT NULL DEFAULT 'PENDENTE',
  `idioma` varchar(10) NOT NULL DEFAULT 'pt-BR',
  `texto_extraido` longtext DEFAULT NULL,
  `metadados` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadados`)),
  `processado_em` datetime(6) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_documentos_public_id` (`public_id`),
  KEY `idx_documentos_tenant_tipo` (`marcenaria_id`,`tipo`,`criado_em`),
  KEY `idx_documentos_entidade` (`marcenaria_id`,`entidade_tipo`,`entidade_id`),
  CONSTRAINT `fk_documentos_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_documentos_arquivo` FOREIGN KEY (`arquivo_id`) REFERENCES `arquivos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `documento_paginas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `documento_id` bigint unsigned NOT NULL,
  `numero_pagina` int unsigned NOT NULL,
  `texto` longtext DEFAULT NULL,
  `layout_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`layout_json`)),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_documento_pagina` (`documento_id`,`numero_pagina`),
  CONSTRAINT `fk_documento_paginas_documento` FOREIGN KEY (`documento_id`) REFERENCES `documentos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `documento_chunks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `documento_id` bigint unsigned NOT NULL,
  `pagina_inicial` int unsigned DEFAULT NULL,
  `pagina_final` int unsigned DEFAULT NULL,
  `ordem` int unsigned NOT NULL,
  `conteudo` text NOT NULL,
  `token_count` int unsigned DEFAULT NULL,
  `sha256` char(64) DEFAULT NULL,
  `embedding_model` varchar(120) DEFAULT NULL,
  `vector_store` varchar(60) DEFAULT NULL,
  `vector_external_id` varchar(255) DEFAULT NULL COMMENT 'ID no pgvector, Qdrant, Pinecone, OpenSearch etc.',
  `metadados` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadados`)),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_documento_chunks_public_id` (`public_id`),
  UNIQUE KEY `uk_documento_chunk_ordem` (`documento_id`,`ordem`),
  KEY `idx_documento_chunks_vector_id` (`vector_external_id`),
  CONSTRAINT `fk_documento_chunks_documento` FOREIGN KEY (`documento_id`) REFERENCES `documentos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- IA
-- =========================================================

CREATE TABLE `ia_assistentes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `codigo` varchar(80) NOT NULL,
  `nome` varchar(180) NOT NULL,
  `finalidade` varchar(60) NOT NULL COMMENT 'ORCAMENTO, CONTRATO, ANALISE_PDF, IMPORTACAO, COMERCIAL, PRODUCAO, GERAL',
  `system_prompt` longtext NOT NULL,
  `modelo` varchar(120) DEFAULT NULL,
  `temperatura` decimal(4,3) DEFAULT NULL,
  `configuracoes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`configuracoes`)),
  `versao` int unsigned NOT NULL DEFAULT 1,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ia_assistente` (`marcenaria_id`,`codigo`,`versao`),
  CONSTRAINT `fk_ia_assistentes_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ia_conversas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `usuario_id` bigint unsigned NOT NULL,
  `assistente_id` bigint unsigned DEFAULT NULL,
  `titulo` varchar(255) DEFAULT NULL,
  `contexto_entidade_tipo` varchar(40) DEFAULT NULL,
  `contexto_entidade_id` bigint unsigned DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'ATIVA',
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `atualizado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ia_conversas_public_id` (`public_id`),
  KEY `idx_ia_conversas_usuario` (`marcenaria_id`,`usuario_id`,`atualizado_em`),
  CONSTRAINT `fk_ia_conversas_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ia_conversas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ia_conversas_assistente` FOREIGN KEY (`assistente_id`) REFERENCES `ia_assistentes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ia_mensagens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `conversa_id` bigint unsigned NOT NULL,
  `papel` varchar(20) NOT NULL COMMENT 'SYSTEM, USER, ASSISTANT, TOOL',
  `conteudo` longtext DEFAULT NULL,
  `tool_name` varchar(120) DEFAULT NULL,
  `tool_call_id` varchar(255) DEFAULT NULL,
  `payload_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload_json`)),
  `tokens_entrada` int unsigned DEFAULT NULL,
  `tokens_saida` int unsigned DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_ia_mensagens_conversa_data` (`conversa_id`,`criado_em`),
  CONSTRAINT `fk_ia_mensagens_conversa` FOREIGN KEY (`conversa_id`) REFERENCES `ia_conversas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ia_execucoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `public_id` char(36) NOT NULL DEFAULT (uuid()),
  `marcenaria_id` bigint unsigned NOT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `conversa_id` bigint unsigned DEFAULT NULL,
  `assistente_id` bigint unsigned DEFAULT NULL,
  `operacao` varchar(80) NOT NULL,
  `modelo` varchar(120) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'INICIADA',
  `entrada_hash` char(64) DEFAULT NULL,
  `latencia_ms` int unsigned DEFAULT NULL,
  `tokens_entrada` int unsigned DEFAULT NULL,
  `tokens_saida` int unsigned DEFAULT NULL,
  `custo_estimado` decimal(18,8) DEFAULT NULL,
  `erro_codigo` varchar(120) DEFAULT NULL,
  `erro_mensagem` text DEFAULT NULL,
  `iniciado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `finalizado_em` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ia_execucoes_public_id` (`public_id`),
  KEY `idx_ia_exec_tenant_data` (`marcenaria_id`,`iniciado_em`,`operacao`),
  CONSTRAINT `fk_ia_exec_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ia_exec_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ia_exec_conversa` FOREIGN KEY (`conversa_id`) REFERENCES `ia_conversas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ia_exec_assistente` FOREIGN KEY (`assistente_id`) REFERENCES `ia_assistentes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ia_fontes_resposta` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ia_mensagem_id` bigint unsigned NOT NULL,
  `documento_chunk_id` bigint unsigned NOT NULL,
  `score` decimal(9,6) DEFAULT NULL,
  `trecho_utilizado` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ia_fonte` (`ia_mensagem_id`,`documento_chunk_id`),
  CONSTRAINT `fk_ia_fontes_mensagem` FOREIGN KEY (`ia_mensagem_id`) REFERENCES `ia_mensagens` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ia_fontes_chunk` FOREIGN KEY (`documento_chunk_id`) REFERENCES `documento_chunks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ia_feedback` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ia_mensagem_id` bigint unsigned NOT NULL,
  `usuario_id` bigint unsigned NOT NULL,
  `avaliacao` tinyint NOT NULL COMMENT '-1 negativo, 1 positivo',
  `comentario` varchar(1000) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ia_feedback_usuario_mensagem` (`ia_mensagem_id`,`usuario_id`),
  CONSTRAINT `fk_ia_feedback_mensagem` FOREIGN KEY (`ia_mensagem_id`) REFERENCES `ia_mensagens` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ia_feedback_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_ia_feedback_avaliacao` CHECK (`avaliacao` IN (-1,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- NOTIFICAÇÕES / EVENTOS / AUDITORIA
-- =========================================================

CREATE TABLE `notificacoes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned NOT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `tipo` varchar(50) NOT NULL,
  `titulo` varchar(255) NOT NULL,
  `mensagem` text NOT NULL,
  `entidade_tipo` varchar(40) DEFAULT NULL,
  `entidade_id` bigint unsigned DEFAULT NULL,
  `lida_em` datetime(6) DEFAULT NULL,
  `criado_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_notificacoes_usuario_lida` (`marcenaria_id`,`usuario_id`,`lida_em`,`criado_em`),
  CONSTRAINT `fk_notificacoes_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_notificacoes_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `outbox_eventos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned DEFAULT NULL,
  `aggregate_type` varchar(80) NOT NULL,
  `aggregate_id` varchar(80) NOT NULL,
  `event_type` varchar(120) NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `ocorrido_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `publicado_em` datetime(6) DEFAULT NULL,
  `tentativas` int unsigned NOT NULL DEFAULT 0,
  `ultimo_erro` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_outbox_pendente` (`publicado_em`,`ocorrido_em`),
  CONSTRAINT `fk_outbox_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `auditoria_eventos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `marcenaria_id` bigint unsigned DEFAULT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL,
  `acao` varchar(80) NOT NULL,
  `entidade_tipo` varchar(80) NOT NULL,
  `entidade_id` varchar(80) DEFAULT NULL,
  `dados_antes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`dados_antes`)),
  `dados_depois` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`dados_depois`)),
  `correlation_id` varchar(100) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `ocorrido_em` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_auditoria_tenant_data` (`marcenaria_id`,`ocorrido_em`),
  KEY `idx_auditoria_entidade` (`entidade_tipo`,`entidade_id`,`ocorrido_em`),
  CONSTRAINT `fk_auditoria_marcenaria` FOREIGN KEY (`marcenaria_id`) REFERENCES `marcenarias` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_auditoria_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- SEEDS FIXOS
-- =========================================================

INSERT INTO `plataforma_config` (`id`,`nome_plataforma`,`versao_schema`)
VALUES (1,'ModuNexa','2.0.0')
ON DUPLICATE KEY UPDATE `nome_plataforma`=VALUES(`nome_plataforma`), `versao_schema`=VALUES(`versao_schema`);

INSERT INTO `perfis` (`codigo`,`nome`,`escopo`) VALUES
('PLATAFORMA_ADMIN','Administrador ModuNexa','PLATAFORMA'),
('MARCENARIA_ADMIN','Administrador da marcenaria','MARCENARIA'),
('VENDEDOR','Vendedor','MARCENARIA'),
('PROJETISTA','Projetista','MARCENARIA'),
('PRODUCAO','Produção','MARCENARIA'),
('MONTADOR','Montador','MARCENARIA')
ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);


-- Ambientes e especificações vindos da planilha ambientes.xlsx
INSERT INTO `ambientes_modelo` (`nome`) VALUES ('BWC Social') ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Corrediças ocultas Hetich',1 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Corrediças telescópicas',2 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Dobradiças Blum',3 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Dobradiças FGV',4 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Dobradiças Hetich',5 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'GAVETAS METÁLICAS',6 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Interna BRANCO TX',7 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Interna COR',8 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Porta talher Santori',9 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambiente_modelo_especificacoes` (`ambiente_modelo_id`,`descricao`,`ordem`) SELECT `id`,'Tulha',10 FROM `ambientes_modelo` WHERE `nome`='BWC Social' ON DUPLICATE KEY UPDATE `ordem`=VALUES(`ordem`);
INSERT INTO `ambientes_modelo` (`nome`) VALUES ('Cozinha') ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);
INSERT INTO `ambientes_modelo` (`nome`) VALUES ('Lavabo') ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);
INSERT INTO `ambientes_modelo` (`nome`) VALUES ('Living') ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);
INSERT INTO `ambientes_modelo` (`nome`) VALUES ('Sala de estar') ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);
INSERT INTO `ambientes_modelo` (`nome`) VALUES ('Sala de jantar') ON DUPLICATE KEY UPDATE `nome`=VALUES(`nome`);

-- Categorias e itens de referência vindos da planilha categorias.xlsx
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Armário por metro','AREA','m²','(largura * altura) * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Painel por metro','AREA','m²','(largura * altura) * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Painel ripado','QUANTIDADE','un','quantidade * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Mão de obra - Especiais','QUANTIDADE','un','quantidade * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Puxadores','QUANTIDADE','un','quantidade * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Adicionais','QUANTIDADE','un','quantidade * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Kits e ferragens','QUANTIDADE','un','quantidade * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Item de valor fixo','QUANTIDADE','un','quantidade * valor') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_categorias` (`nome`,`tipo_calculo`,`unidade_padrao`,`formula_legada`) VALUES ('Cálculo por material','MATERIAL_MARKUP','%','(quantidade * markup) + custo') ON DUPLICATE KEY UPDATE `tipo_calculo`=VALUES(`tipo_calculo`),`unidade_padrao`=VALUES(`unidade_padrao`),`formula_legada`=VALUES(`formula_legada`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário alto - Interna branco tx',2.6,NULL,0.00,1250.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário alto - Interna cor',2.6,NULL,0.00,1850.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário inferior - interna cor branco tx',1,NULL,0.00,1650.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário inferior - interna cor',1,NULL,0.00,1850.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário superior - 50 cm - interna branco tx',1,NULL,0.00,1650.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário superior - 50 cm - interna cor',1,NULL,0.00,1850.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário superior - 40 cm - interna branco tx',1,NULL,0.00,1550.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário superior - 40 cm - interna cor',1,NULL,0.00,1750.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário 2 gavetas - interna branco tx',1,NULL,0.00,1900.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário 2 gavetas - interna cor',1,NULL,0.00,1950.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário 4 gavetas - interna branco tx',1,NULL,0.00,2100.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário 4 gavetas - interna cor',1,NULL,0.00,2190.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário inferior - interna branco tx',1,NULL,0.00,1400.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário superior - interna branco tx',1,NULL,0.00,1100.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário superior - interna cor',1,NULL,0.00,1200.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Armário sem portas',1,NULL,0.00,1490.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Home',0.7,NULL,0.00,1650.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Gaveteiro suspenso',0.7,NULL,0.00,1650.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Mesa de cabeceira',1,NULL,0.00,1650.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Nicho aberto',1,NULL,0.00,1700.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Nicho lateral de Armário',2.6,NULL,0.00,1450.00,'{"alturaPadraoOrigemPlanilha": true}' FROM `catalogo_modelo_categorias` WHERE `nome`='Armário por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel de parede',0,NULL,0.00,350.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Prateleira simples',0,NULL,0.00,340.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Prateleira duplada',0,NULL,0.00,680.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel teto',0,NULL,0.00,570.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Porta de passagem',0,NULL,0.00,1380.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Parede de mdf',0,NULL,0.00,750.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel por metro' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado (Ripas 18mm)',0,NULL,0.00,950.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado (Ripas 15mm)',0,NULL,0.00,950.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado (Ripas 50mm)',0,NULL,0.00,750.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado (Ripas 70mm)',0,NULL,0.00,750.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado (Ripas 10mm)',0,NULL,0.00,750.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado  especial',0,NULL,0.00,1100.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Painel ripado 6mm em laca',0,NULL,0.00,1100.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Muxarabi usinado',0,NULL,0.00,2100.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Muxarabi Treliçado',0,NULL,0.00,3100.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Painel ripado' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Meia esquadria',0,'valor por canto',0.00,600.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Mão de obra - Especiais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Curva móvel inferior e superior',0,'valor por canto P',0.00,1200.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Mão de obra - Especiais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Curva móvel grande',0,'valor por canto G',0.00,2500.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Mão de obra - Especiais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Curva grande',0,'valor por curva',0.00,2500.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Mão de obra - Especiais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Moldura provençal',0,'corte e borda',0.00,200.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Mão de obra - Especiais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Fecho toque',0,'Ferragem',0.00,91.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cava 30',0,'Marcenaria',0.00,60.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Meia cava',0,'Marcenaria',0.00,350.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cava esculpida P',0,'Marcenaria',0.00,70.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cava esculpida M',0,'Marcenaria',0.00,90.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cava esculpida G',0,'Marcenaria',0.00,150.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'VERSATILE PEQUENO',0,'PORTA PEQUENA',0.00,45.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'VERSATILE GRANDE',0,'PORTA GRANDE',0.00,110.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'M08',0,'usinado',0.00,85.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Perfil Y',0,'metro',0.00,45.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Ponteira perfil Y',0,'2 unidades',0.00,12.50,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cava metálica',0,'C e J',0.00,40.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Ponteira cava metálica',0,'2 unidades',0.00,13.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Puxadores' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Kit Dominus; por porta',0,NULL,0.00,1180.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Adicionais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Adicional gaveta',0,NULL,0.00,375.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Adicionais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'KIT RO 85 max',0,NULL,0.00,300.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Adicionais' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Kit pivotante p/ porta de passagem',0,'1 por porta',0.00,650.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Kit de dobradiças invisíveis p/ porta de passagem',0,'2 por porta',0.00,991.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Kit Ro para porta de passagem',0,'3 por porta',0.00,950.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Corrediças invisíveis',0,'par por gaveta',0.00,120.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Divisor de talheres inox',0,'cada 45 cm',0.00,759.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Divisor de talheres modular',0,'cada 10 cm',0.00,151.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Dobradiças blum - porta p',0,'3 dobradiças',0.00,125.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Dobradiças blum - porta g',0,'5 dobradiças',0.00,313.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Kits e ferragens' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Torre quente',0,'até 80 cm',0.00,3990.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cama de solteiro',0,'Simples',0.00,2900.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cama solteiro especial',0,'Com gavetas',0.00,3590.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cama de casal',0,'Simples',0.00,3690.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Cama de casal especial',0,'Com gavetas',0.00,4290.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Pérgolas 3',0,'3 cm de espessura',0.00,350.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Pérgolas 45',0,'4,5 cm de espessura',0.00,450.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Pérgolas 6',0,'6 cm de espessura',0.00,650.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Pérgolas 10',0,'10 cm de espessura',0.00,850.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Item de valor fixo' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa Branca 6 mm',0,NULL,0.00,280.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa Branca 15 mm',0,NULL,0.00,310.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa Branca 18 mm',0,NULL,0.00,300.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa madeirada 6 mm',0,NULL,0.00,310.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa madeirada 15 mm',0,NULL,0.00,380.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa madeirada 18 mm',0,NULL,0.00,410.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa variada 6 mm',0,NULL,0.00,0.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa variada 15 mm',0,NULL,0.00,0.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Chapa variada 18 mm',0,NULL,0.00,580.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Porta 2 dobradiças',0,NULL,0.00,43.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Porta 5 dobradiças',0,NULL,0.00,215.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Porta Basculante 1 pistoes',0,NULL,0.00,80.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Corrediça telescópica',0,NULL,0.00,60.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Fita de borda 22',0,NULL,0.00,48.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Fita de borda 33',0,NULL,0.00,75.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'Fita de borda 64',0,NULL,0.00,136.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'RODÍZIO',0,NULL,0.00,29.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);
INSERT INTO `catalogo_modelo_itens` (`categoria_modelo_id`,`descricao`,`altura_padrao`,`observacao`,`markup_percentual`,`preco_base`,`parametros`) SELECT `id`,'OUTRO',0,NULL,0.00,0.00,NULL FROM `catalogo_modelo_categorias` WHERE `nome`='Cálculo por material' ON DUPLICATE KEY UPDATE `altura_padrao`=VALUES(`altura_padrao`),`observacao`=VALUES(`observacao`),`markup_percentual`=VALUES(`markup_percentual`),`preco_base`=VALUES(`preco_base`),`parametros`=VALUES(`parametros`);

-- Exemplo de etapas padrão que a API pode copiar ao criar uma nova marcenaria:
-- COMERCIAL: NOVO_LEAD -> NEGOCIACAO -> PROPOSTA_ENVIADA -> FECHAMENTO
-- PRODUÇÃO: PROJETO_PRONTO -> MATERIAL_COMPRADO -> MATERIAL_CORTADO ->
--           MARCENARIA_PRONTA -> ENTREGUE -> MONTANDO -> FINALIZADO
--
-- Regras contratuais observadas nos anexos devem ser configuráveis em `regras_negocio`
-- e materializadas em `contrato_prazos`, por exemplo:
-- projeto de aprovação até 15 dias corridos após medição;
-- cliente aprova em até 2 dias úteis;
-- entrega em até 60 dias úteis após aprovação;
-- montagem inicia em até 5 dias úteis após entrega;
-- garantia de 5 anos para madeira e 1 ano para ferragens.
--
-- A API deve calcular dias úteis na camada de domínio (com calendário/feriados),
-- não em trigger SQL, para manter regra testável e versionável.

INSERT INTO `__efmigrationshistory` (`MigrationId`,`ProductVersion`)
VALUES ('20260824_ModunexaOptimizedSchema','9.0.0')
ON DUPLICATE KEY UPDATE `ProductVersion`=VALUES(`ProductVersion`);

SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
