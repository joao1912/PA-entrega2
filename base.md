# Modelagem do Banco de Dados e Dicionário de Dados

**Unidade Curricular:** Projeto Aplicado I  
**Tema:** Modelagem e Implementação de Banco de Dados (Entrega 02)  
**Professor:** Prof. MSc. Hugo Menezes Barra  
**Empresa Parceira:** Schulz S.A.  
**Script de criação:** `03_banco.sql` (SQLite)

---

## 1. Problema

No laboratório de Metrologia da Schulz S.A., as medições e os certificados de calibração eram controlados em planilhas Excel/CSV soltas. Isso causava:

- **Redundância:** nome do técnico, setor, fabricante e dados do instrumento eram redigitados em cada arquivo.
- **Erros de digitação:** grafias diferentes para o mesmo dado.
- **Planilhas corrompidas:** fórmulas quebradas (`#VALUE!`, `#NAME?`, `#DIV/0!`) que comprometiam a confiabilidade das medições.

A solução foi migrar os dados para um banco relacional em SQLite, normalizado a partir dessas planilhas.

---

## 2. De planilha para banco: as 3 tabelas

Cada linha do CSV original misturava três tipos de informação: **quem** mediu, **o que** foi medido e **o resultado**. O banco separa cada uma na sua tabela:

```
┌──────────────┐        ┌───────────────┐
│   tecnicos   │        │  equipamentos │
└──────┬───────┘        └───────┬───────┘
       │ 1                      │ 1
       │                        │
       └──────┐        ┌────────┘
            N │        │ N
             ┌┴────────┴┐
             │ medicoes │
             └──────────┘
```

| Tabela | O que guarda |
|---|---|
| `tecnicos` | Metrologistas, signatários e administradores |
| `equipamentos` | Dispositivos, gabaritos e instrumentos (TAG, fabricante, modelo, série, localização) |
| `medicoes` | Cada parâmetro medido numa calibração, ligado a um técnico e a um equipamento por chave estrangeira |

---

## 3. Normalização

**1FN: valores atômicos, sem grupos repetidos.**
No CSV, vários resultados vinham agrupados. Em `medicoes`, cada linha é **um parâmetro avaliado** (`parametro_avaliado`), com leituras individuais (`medida_1`, `medida_2`), média e tolerâncias em colunas numéricas separadas.

**2FN: sem dependência parcial.**
Fabricante, modelo e série dependem do equipamento, e cargo e matrícula dependem do técnico. Nenhum deles depende da medição, por isso ficam em `equipamentos` e `tecnicos`, e a medição só guarda `id_equipamento` e `id_tecnico`.

**3FN: sem dependência transitiva.**
Antes, nome e perfil do técnico e dados do equipamento estavam gravados em cada registro de medição. Se algo mudasse (cargo, setor, fabricante), os registros históricos ficariam inconsistentes. Agora cada dado existe em **um único lugar**, e `medicoes` guarda apenas referências.

---

## 4. Por que o SQL é assim

| Decisão no script | Motivo |
|---|---|
| `PRAGMA foreign_keys = ON` | O SQLite não aplica chaves estrangeiras por padrão; é preciso ativar. |
| `INTEGER PRIMARY KEY AUTOINCREMENT` | Chave substituta simples e nunca reutilizada, independente de matrícula ou TAG. |
| `UNIQUE` em `matricula` e `codigo_tag` | Identificadores de negócio não podem se repetir. |
| `CHECK` em `cargo_perfil` e `status_conformidade` | Limita os valores aceitos e evita as variações de grafia das planilhas. |
| `NOT NULL` nos campos de resultado | Não existe certificado sem nominal, tolerância, média, desvio e incerteza. |
| `medida_1` e `medida_2` aceitam `NULL` | Nem todo parâmetro tem duas leituras. |
| `DEFAULT 'Schulz'` em `fabricante` | Equipamentos fabricados internamente dispensam preenchimento. |
| `ON DELETE RESTRICT` | Impede apagar técnico ou equipamento que já tenha medições, preservando o histórico. |
| `ON UPDATE CASCADE` | Se uma chave mudar, as medições acompanham. |
| Índices em `id_equipamento`, `id_tecnico` e `ordem_servico` | Aceleram os `JOIN`s e a busca por O.S. na geração de certificados. |
| `data_medicao` como `TEXT` (`YYYY-MM-DD`) | O SQLite não tem tipo de data; esse formato ordena e compara corretamente. |

**Benefícios para o MVP:**
- **Rastreabilidade:** todo certificado aponta para o equipamento e o técnico exatos.
- **Integridade:** as chaves estrangeiras impedem medições órfãs.
- **Menos redundância:** arquivo menor e consultas mais simples.

---

## 5. Dicionário de Dados

### `tecnicos`

| Campo | Tipo | Chave | Restrição | Descrição |
|---|---|---|---|---|
| `id_tecnico` | INTEGER | PK | AUTOINCREMENT | Identificador do técnico. |
| `nome` | TEXT | | NOT NULL | Nome completo (ex: "José A. Rosa Jr"). |
| `matricula` | TEXT | | UNIQUE, NOT NULL | Matrícula na Schulz. |
| `setor` | TEXT | | NOT NULL | Setor (ex: "Metrologia", "Usinagem"). |
| `cargo_perfil` | TEXT | | NOT NULL, CHECK | `Metrologista`, `Signatario Autorizado` ou `Administrador`. |

### `equipamentos`

| Campo | Tipo | Chave | Restrição | Descrição |
|---|---|---|---|---|
| `id_equipamento` | INTEGER | PK | AUTOINCREMENT | Identificador do equipamento. |
| `codigo_tag` | TEXT | | UNIQUE, NOT NULL | TAG do dispositivo (ex: "500.008"). |
| `denominacao` | TEXT | | NOT NULL | Nome descritivo do dispositivo. |
| `fabricante` | TEXT | | NOT NULL, DEFAULT 'Schulz' | Fabricante (ex: "Carl Zeiss"). |
| `modelo` | TEXT | | | Modelo do equipamento. |
| `numero_serie` | TEXT | | | Número de série. |
| `setor_localizacao` | TEXT | | | Setor onde o equipamento está. |

### `medicoes`

| Campo | Tipo | Chave | Restrição | Descrição |
|---|---|---|---|---|
| `id_medicao` | INTEGER | PK | AUTOINCREMENT | Identificador do registro. |
| `id_equipamento` | INTEGER | FK | NOT NULL → `equipamentos` | Equipamento aferido. |
| `id_tecnico` | INTEGER | FK | NOT NULL → `tecnicos` | Técnico executor. |
| `ordem_servico` | TEXT | | NOT NULL | Número da O.S. da calibração. |
| `data_medicao` | TEXT | | NOT NULL | Data no formato `YYYY-MM-DD`. |
| `temperatura_ambiente` | REAL | | NOT NULL | Temperatura da sala no ensaio (ºC). |
| `parametro_avaliado` | TEXT | | NOT NULL | Característica medida (ex: "PLANICIDADE_REF"). |
| `valor_nominal` | REAL | | NOT NULL | Valor nominal (mm). |
| `tolerancia_superior` | REAL | | NOT NULL | Tolerância `Tol +` (mm). |
| `tolerancia_inferior` | REAL | | NOT NULL | Tolerância `Tol -` (mm). |
| `medida_1` | REAL | | | Primeira leitura da MMC Zeiss Calypso. |
| `medida_2` | REAL | | | Segunda leitura da MMC Zeiss Calypso. |
| `media_obtida` | REAL | | NOT NULL | Média das leituras. |
| `desvio_calculado` | REAL | | NOT NULL | Desvio em relação ao nominal. |
| `incerteza_expandida_u` | REAL | | NOT NULL | Incerteza expandida U (k = 2). |
| `status_conformidade` | TEXT | | NOT NULL, CHECK | `CONFORME` ou `NAO_CONFORME`. |