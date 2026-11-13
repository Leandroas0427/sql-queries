# sql-queries

Este repositório reúne consultas SQL desenvolvidas para extração, tratamento, unificação e cruzamento de dados do setor logístico.

## Índice de Scripts e Conceitos

| Arquivo | Descrição / Regra de Negócio | Principais Conceitos SQL |
| :--- | :--- | :--- |
| `consulta_de_fretes.sql` | Consulta analítica de fretes consolidando SLAs de carregamento/descarga, informações operacionais e financeiras. | Window Functions (`ROW_NUMBER() OVER`), CTEs (`WITH`), `FILTER (WHERE)`, Funções de Data/Intervalo (`INTERVAL`, `TO_TIMESTAMP`), `CASE WHEN`, Typecasting |
| `ofertas_consolidadas.sql` | Unificação e agregação de ofertas de compra (ociosidade) e venda, calculando total de viagens, valor médio e volumetria por rota e parceiro. | `UNION ALL`, CTEs (`WITH`), Agregações (`COUNT`, `SUM`, `AVG`), `GROUP BY`, `CASE WHEN`, Typecasting defensivo (`::text`, `::numeric`) |

## 🛠️ Tecnologias Utilizadas
- **SGBD:** PostgreSQL 🐘
- **Linguagem:** SQL
