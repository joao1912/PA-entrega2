-- ====================================================================
-- PROJETO APLICADO I - UNISENAI / SCHULZ S.A.
-- Entrega 02: Script DDL de Criação do Banco de Dados Relacional (SQLite)
-- Arquivo: 03_banco.sql
-- ====================================================================

-- Ativa o suporte a chaves estrangeiras no SQLite
PRAGMA foreign_keys = ON;

-- Limpeza preventiva de tabelas caso já existam
DROP TABLE IF EXISTS medicoes;
DROP TABLE IF EXISTS equipamentos;
DROP TABLE IF EXISTS tecnicos;

-- ====================================================================
-- TABELA 1: tecnicos
-- Armazena os dados cadastrais dos metrologistas, técnicos e signatários
-- ====================================================================
CREATE TABLE tecnicos (
    id_tecnico INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    matricula TEXT UNIQUE NOT NULL,
    setor TEXT NOT NULL,
    cargo_perfil TEXT NOT NULL CHECK (cargo_perfil IN ('Metrologista', 'Signatario Autorizado', 'Administrador'))
);

-- ====================================================================
-- TABELA 2: equipamentos
-- Cadastra os dispositivos de controle, gabaritos e instrumentos calibrados
-- ====================================================================
CREATE TABLE equipamentos (
    id_equipamento INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_tag TEXT UNIQUE NOT NULL,
    denominacao TEXT NOT NULL,
    fabricante TEXT NOT NULL DEFAULT 'Schulz',
    modelo TEXT,
    numero_serie TEXT,
    setor_localizacao TEXT
);

-- ====================================================================
-- TABELA 3: medicoes
-- Armazena as sessões de calibração, medições e cálculo de incertezas
-- ====================================================================
CREATE TABLE medicoes (
    id_medicao INTEGER PRIMARY KEY AUTOINCREMENT,
    id_equipamento INTEGER NOT NULL,
    id_tecnico INTEGER NOT NULL,
    ordem_servico TEXT NOT NULL,
    data_medicao TEXT NOT NULL,
    temperatura_ambiente REAL NOT NULL,
    parametro_avaliado TEXT NOT NULL,
    valor_nominal REAL NOT NULL,
    tolerancia_superior REAL NOT NULL,
    tolerancia_inferior REAL NOT NULL,
    medida_1 REAL,
    medida_2 REAL,
    media_obtida REAL NOT NULL,
    desvio_calculado REAL NOT NULL,
    incerteza_expandida_u REAL NOT NULL,
    status_conformidade TEXT NOT NULL CHECK (status_conformidade IN ('CONFORME', 'NAO_CONFORME')),
    FOREIGN KEY (id_equipamento) REFERENCES equipamentos(id_equipamento) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_tecnico) REFERENCES tecnicos(id_tecnico) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ====================================================================
-- CRIAÇÃO DE ÍNDICES PARA OTIMIZAÇÃO DE CONSULTAS (JOINs)
-- ====================================================================
CREATE INDEX idx_medicoes_equipamento ON medicoes(id_equipamento);
CREATE INDEX idx_medicoes_tecnico ON medicoes(id_tecnico);
CREATE INDEX idx_medicoes_os ON medicoes(ordem_servico);

-- ====================================================================
-- DADOS INICIAIS DE TESTE (SEEDING BASEADO NOS CSVs DA SCHULZ S.A.)
-- ====================================================================

-- Inserção de Técnicos / Signatários reais das planilhas
INSERT INTO tecnicos (nome, matricula, setor, cargo_perfil) VALUES
('José A. Rosa Jr', 'MET-5001', 'Metrologia', 'Metrologista'),
('Cleocir de Souza', 'USI-3042', 'Usinagem', 'Metrologista'),
('João Carlos Gomes de Oliveira', 'SIG-0004', 'Metrologia', 'Signatario Autorizado');

-- Inserção de Equipamentos / Dispositivos reais
INSERT INTO equipamentos (codigo_tag, denominacao, fabricante, modelo, numero_serie, setor_localizacao) VALUES
('500.008', 'Dispositivo de Controle de Peças Usinadas', 'CDM', 'Gabarito Dimensional', 'SN-2022-01', 'Usinagem'),
('500.011', 'Máquina de Medição por Coordenadas (MMC)', 'Carl Zeiss', 'Contura G2', '502390', 'Metrologia');

-- Inserção de Registros de Medição reais (Extraídos do arquivo Registro MMC-Report.csv)
INSERT INTO medicoes (
    id_equipamento, id_tecnico, ordem_servico, data_medicao, temperatura_ambiente,
    parametro_avaliado, valor_nominal, tolerancia_superior, tolerancia_inferior,
    medida_1, medida_2, media_obtida, desvio_calculado, incerteza_expandida_u, status_conformidade
) VALUES
(1, 1, 'OS-2026-8841', '2026-08-13', 20.2, 'PLANICIDADE_REF', 0.0000, 0.0500, 0.0000, 0.0022, 0.0023, 0.00225, 0.00225, 0.0010, 'CONFORME'),
(1, 1, 'OS-2026-8841', '2026-08-13', 20.2, 'ENTRE CENTROS_REF', 0.0000, 0.0400, 0.0000, 0.0274, 0.0274, 0.02740, 0.02740, 0.0010, 'CONFORME'),
(1, 1, 'OS-2026-8841', '2026-08-13', 20.2, '62P_DIÂMETRO 1', 6.0750, 0.0100, -0.0100, 6.0787, 6.0787, 6.07870, 0.00370, 0.0010, 'CONFORME');
