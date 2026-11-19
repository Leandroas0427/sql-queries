# sql-queries

Este repositório reúne consultas SQL desenvolvidas para extração, tratamento, unificação e cruzamento de dados.

## Índice de Scripts e Conceitos

| Arquivo | Descrição / Regra de Negócio | Principais Conceitos SQL |
| :--- | :--- | :--- |
| `consulta_fretes.sql` | Consulta analítica de fretes (1 registro por `frete_id`) consolidando SLAs de carregamento/descarga (On Time e TMO), informações operacionais (embarcadores via `trade_name`, veículo mais recente) e financeiras. | Window Functions (`ROW_NUMBER() OVER` com `MAX` e `GROUP BY`), CTEs (`WITH`), Múltiplos `LEFT JOIN`, Agregação Condicional (`CASE WHEN`), Funções de Data/Intervalo (`EXTRACT`, `INTERVAL`), Tratamento de Strings e Nulos (`UPPER`, `REPLACE`, `NULLIF`, `COALESCE`), Typecasting e Arredondamento (`CAST`, `ROUND`) |
| `ofertas_consolidadas.sql` | Unificação e agregação de ofertas de compra (ociosidade) e venda, calculando total de viagens, valor médio e volumetria por rota e parceiro. | `UNION ALL`, CTEs (`WITH`), Múltiplos `LEFT JOIN`, Agregações (`COUNT`, `SUM`, `AVG`), `GROUP BY`, `CASE WHEN`, Typecasting ANSI (`CAST` para `DATE`, `VARCHAR`, `INTEGER`) |

## 🛠️ Tecnologias Utilizadas
- **SGBD:** PostgreSQL
- **Linguagem:** SQL (Padrão ANSI)
