# Avaliacao BD - Parte 2

Entrega complementar do banco de dados da plataforma **Simulador ENEM**.

## Como executar

1. Execute a estrutura da parte 1:

```sql
\i schema.sql
\i triggers.sql
\i rls.sql
```

Ou execute o arquivo unico:

```sql
\i entrega_completa.sql
```

2. Execute a populacao da parte 2:

```sql
\i parte2/01_popular_tabelas.sql
```

3. Execute cada consulta da parte 2:

- `02_escolas_total_alunos.sql`
- `03_alunos_sem_sessao.sql`
- `04_respostas_questao_45_por_escola.sql`
- `05_taxa_media_acerto_por_escola.sql`
- `06_auditoria_totalizadores_sessoes.sql`
- `07_hall_da_fama_semanal.sql`

Os CSVs esperados estao em `parte2/resultados`.

## Observacoes

- O enunciado usa nomes em ingles, como `student`, `quiz_sessions` e `is_correct`.
- A parte 1 deste projeto foi modelada em portugues, entao as consultas usam os nomes reais do schema:
  - `student` = `aluno`
  - `quiz_sessions` = `app.sessoes_simulado`
  - `is_correct` = `app.respostas_simulado.acertou`
- O CNPJ da escola pedida no enunciado e armazenado sem pontuacao por causa da constraint do schema.
  A consulta 4 normaliza o valor para aceitar o formato `12.345.678/0001-99`.
