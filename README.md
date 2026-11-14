# sql-queries

Este repositório reúne consultas SQL desenvolvidas para extração, tratamento, unificação e cruzamento de dados do setor logístico[cite: 6].

## Índice de Scripts e Conceitos

| Arquivo | Descrição / Regra de Negócio | Principais Conceitos SQL |
| :--- | :--- | :--- |
| `consulta_de_fretes.sql` | Consulta analítica de fretes consolidando SLAs de carregamento/descarga, informações operacionais e financeiras[cite: 6]. | Window Functions (`ROW_NUMBER() OVER`), CTEs (`WITH`), Múltiplos `LEFT JOIN`, Agregação Condicional (`CASE WHEN`), Funções de Data/Intervalo (`EXTRACT`, `INTERVAL`), Tratamento de Strings e Nulos (`REPLACE`, `NULLIF`, `COALESCE`), Typecasting ANSI (`CAST`)[cite: 4, 6] |
| `ofertas_consolidadas.sql` | Unificação e agregação de ofertas de compra (ociosidade) e venda, calculando total de viagens, valor médio e volumetria por rota e parceiro[cite: 6]. | `UNION ALL`, CTEs (`WITH`), Múltiplos `LEFT JOIN`, Agregações (`COUNT`, `SUM`, `AVG`), `GROUP BY`, `CASE WHEN`, Typecasting ANSI (`CAST` para `DATE`, `VARCHAR`, `BIGINT`)[cite: 5, 6] |

## 🛠️ Tecnologias Utilizadas
- **SGBD:** PostgreSQL 🐘[cite: 6]
- **Linguagem:** SQL (Padrão ANSI)