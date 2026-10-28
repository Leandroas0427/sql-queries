# sql-queries

Este repositório reúne consultas SQL desenvolvidas para extração, tratamento e cruzamento de dados do setor logístico.

## Índice de Scripts e Conceitos

| Arquivo | Descrição / Regra de Negócio | Principais Conceitos SQL |
| :--- | :--- | :--- |
| `fretes_spot_backhaul.sql` | Relatório de fretes operacionais com receitas e despesas. | CTEs (`WITH`), `FILTER (WHERE)`, `LEFT JOIN`, `COALESCE` |
| `matches_compra_venda.sql` | Cruzamento de rotas de compra e venda com cálculo de desvios. | `UNION ALL`, `CASE WHEN`, Funções de Texto (`LEFT`/`RIGHT`), Typecasting |
| `ofertas_compra.sql` | Padronização das ofertas de ociosidade/compra. | `CASE WHEN` condicional, tratamento de Nulos, `::date` |
| `ofertas_venda.sql` | Mapeamento detalhado de ofertas e tarifas de venda. | Junções múltiplas (`LEFT JOIN`), Tratamento de Booleanos |

## 🛠️ Tecnologias Utilizadas
- **SGBD:** PostgreSQL 🐘
- **Linguagem:** SQL
