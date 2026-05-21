# Avaliacao Pratica - Parte 1

Entrega da modelagem de banco de dados da plataforma **"Simulador ENEM"**.

## Autor

- Matheus Machado

## Estrutura do repositorio

- [DER.md](./DER.md): diagrama entidade-relacionamento em Mermaid
- [schema.sql](./schema.sql): criacao de schemas, tipos, tabelas, constraints e indices
- [triggers.sql](./triggers.sql): automacoes e validacoes de negocio
- [rls.sql](./rls.sql): politicas de Row Level Security
- [entrega_completa.sql](./entrega_completa.sql): script unico com toda a entrega

## Premissas adotadas

1. A plataforma usa PostgreSQL.
2. A autenticacao nativa foi modelada por meio da tabela `auth.usuarios`.
3. Senhas nao sao armazenadas nas tabelas de dominio da aplicacao.
4. Todas as entidades principais usam UUID com `gen_random_uuid()`.
5. O banco de questoes usa `JSONB` para `enunciado` e `alternativas`.
6. A plataforma e multitenant em nivel logico, com isolamento por RLS.

## Entidades principais

- `auth.usuarios`: representa a autenticacao nativa do sistema
- `app.perfis`: perfis de usuario vinculados 1:1 a autenticacao
- `app.escolas`: escolas clientes
- `app.matriculas`: vinculo entre alunos e escolas
- `app.questoes`: banco de questoes
- `app.sessoes_simulado`: sessoes de simulados iniciadas pelos alunos
- `app.sessao_questoes`: questoes apresentadas em cada sessao
- `app.respostas_simulado`: respostas dadas pelos alunos

## Regras atendidas

- criacao automatica do perfil quando um usuario e inserido na autenticacao
- papel padrao `aluno` quando nao houver papel inicial informado
- CNPJ unico por escola
- aluno pode estar em varias escolas, mas nao pode ter matricula repetida na mesma escola
- questoes usam JSONB para conteudo flexivel
- exclusao de questao remove automaticamente sessao_questoes e respostas relacionadas
- sessao controla status, horario de inicio, horario de fim, total de questoes e total de acertos
- nao e permitido responder duas vezes a mesma questao na mesma sessao
- RLS separa visao de aluno, administrador escolar e administrador global

## Como executar

Opcao 1: executar o arquivo unico:

```sql
\i entrega_completa.sql
```

Opcao 2: executar por partes:

```sql
\i schema.sql
\i triggers.sql
\i rls.sql
```

## Como simular o usuario logado nas politicas RLS

As politicas usam a configuracao de sessao `app.current_user_id`.

Exemplo:

```sql
set app.current_user_id = '00000000-0000-0000-0000-000000000001';
```

## Observacao

O script foi escrito para ser legivel, modular e fiel ao enunciado da avaliacao, com foco em modelagem relacional, integridade, automacao e seguranca em banco de dados.
