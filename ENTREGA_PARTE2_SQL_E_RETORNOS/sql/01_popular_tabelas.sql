-- Avaliacao BD parte 2
-- Questao 1: popular todas as tabelas com dados validos.
--
-- Execute depois de schema.sql e triggers.sql.
-- O script reinicia os dados de exemplo para garantir resultados deterministico.

begin;

truncate table
    app.respostas_simulado,
    app.sessao_questoes,
    app.sessoes_simulado,
    app.matriculas,
    app.escolas,
    app.questoes,
    app.perfis,
    auth.usuarios
restart identity cascade;

insert into auth.usuarios (id, email, nome_completo, papel_inicial) values
    ('10000000-0000-0000-0000-000000000001', 'marcelo.gomes@simuladorenem.com.br', 'Marcelo Vieira Gomes', 'administrador_global'),
    ('20000000-0000-0000-0000-000000000001', 'patricia.duarte@horizontepaulista.edu.br', 'Patricia Nunes Duarte', 'administrador_escolar'),
    ('20000000-0000-0000-0000-000000000002', 'ricardo.melo@novageracao.edu.br', 'Ricardo Augusto Melo', 'administrador_escolar'),
    ('20000000-0000-0000-0000-000000000003', 'fernanda.barros@sabercerrado.edu.br', 'Fernanda Costa Barros', 'administrador_escolar'),
    ('20000000-0000-0000-0000-000000000004', 'juliana.lima@atlanticosul.edu.br', 'Juliana Peixoto Lima', 'administrador_escolar'),
    ('30000000-0000-0000-0000-000000000001', 'ana.ribeiro@email.com', 'Ana Clara Ribeiro Santos', 'aluno'),
    ('30000000-0000-0000-0000-000000000002', 'bruno.lima@email.com', 'Bruno Henrique Alves Lima', 'aluno'),
    ('30000000-0000-0000-0000-000000000003', 'camila.oliveira@email.com', 'Camila Torres de Oliveira', 'aluno'),
    ('30000000-0000-0000-0000-000000000004', 'diego.pereira@email.com', 'Diego Martins Pereira', 'aluno'),
    ('30000000-0000-0000-0000-000000000005', 'eduarda.fernandes@email.com', 'Eduarda Carvalho Fernandes', 'aluno'),
    ('30000000-0000-0000-0000-000000000006', 'felipe.moreira@email.com', 'Felipe Andrade Moreira', 'aluno'),
    ('30000000-0000-0000-0000-000000000007', 'gabriela.farias@email.com', 'Gabriela Melo Farias', 'aluno'),
    ('30000000-0000-0000-0000-000000000008', 'henrique.carvalho@email.com', 'Henrique Sousa Carvalho', 'aluno'),
    ('30000000-0000-0000-0000-000000000009', 'isabela.azevedo@email.com', 'Isabela Nogueira Azevedo', 'aluno'),
    ('30000000-0000-0000-0000-000000000010', 'joao.reis@email.com', 'Joao Pedro Campos Reis', 'aluno'),
    ('30000000-0000-0000-0000-000000000011', 'laura.freitas@email.com', 'Laura Beatriz Freitas', 'aluno'),
    ('30000000-0000-0000-0000-000000000012', 'matheus.duarte@email.com', 'Matheus Vinicius Duarte', 'aluno'),
    ('30000000-0000-0000-0000-000000000013', 'nathalia.monteiro@email.com', 'Nathalia Rocha Monteiro', 'aluno'),
    ('30000000-0000-0000-0000-000000000014', 'otavio.barbosa@email.com', 'Otavio Lima Barbosa', 'aluno'),
    ('30000000-0000-0000-0000-000000000015', 'sofia.albuquerque@email.com', 'Sofia Mendes Albuquerque', 'aluno');

-- A tabela app.perfis e populada automaticamente pelo trigger
-- trg_auth_usuarios_inicializar_perfil.

insert into app.escolas (id, nome, cnpj, administrador_escolar_id) values
    ('50000000-0000-0000-0000-000000000001', 'Colegio Horizonte Paulista', '12345678000199', '20000000-0000-0000-0000-000000000001'),
    ('50000000-0000-0000-0000-000000000002', 'Escola Tecnica Nova Geracao', '14123456000170', '20000000-0000-0000-0000-000000000002'),
    ('50000000-0000-0000-0000-000000000003', 'Instituto Saber do Cerrado', '23234567000181', '20000000-0000-0000-0000-000000000003'),
    ('50000000-0000-0000-0000-000000000004', 'Colegio Atlantico Sul', '33456789000152', '20000000-0000-0000-0000-000000000004');

insert into app.matriculas (escola_id, aluno_id, data_matricula) values
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '2026-02-03'),
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', '2026-02-04'),
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', '2026-02-05'),
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000007', '2026-02-06'),
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000008', '2026-02-07'),
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000009', '2026-02-08'),
    ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000010', '2026-02-09'),
    ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000004', '2026-02-10'),
    ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000005', '2026-02-11'),
    ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000006', '2026-02-12'),
    ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000011', '2026-02-13'),
    ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000012', '2026-02-14'),
    ('50000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000013', '2026-02-15'),
    ('50000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000014', '2026-02-16'),
    ('50000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000015', '2026-02-17'),
    ('50000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', '2026-02-18'),
    ('50000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000004', '2026-02-19'),
    ('50000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000002', '2026-02-20'),
    ('50000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000005', '2026-02-21'),
    ('50000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000008', '2026-02-22');

with temas (ordem, area, tema) as (
    values
        (1, 'Linguagens', 'interpretacao de campanha educativa sobre leitura'),
        (2, 'Linguagens', 'variacao linguistica em conversa cotidiana'),
        (3, 'Linguagens', 'efeitos de sentido em tirinha jornalistica'),
        (4, 'Linguagens', 'funcao social de texto publicitario'),
        (5, 'Linguagens', 'intertextualidade em poema contemporaneo'),
        (6, 'Ciencias Humanas', 'urbanizacao brasileira e mobilidade urbana'),
        (7, 'Ciencias Humanas', 'formacao territorial e atividades economicas'),
        (8, 'Ciencias Humanas', 'cidadania e participacao politica'),
        (9, 'Ciencias Humanas', 'revolucao industrial e trabalho'),
        (10, 'Ciencias Humanas', 'patrimonio cultural e memoria coletiva'),
        (11, 'Matematica', 'proporcionalidade em consumo de agua'),
        (12, 'Matematica', 'funcao afim em planejamento financeiro'),
        (13, 'Matematica', 'estatistica em pesquisa escolar'),
        (14, 'Matematica', 'probabilidade em sorteio de livros'),
        (15, 'Matematica', 'geometria plana em reforma de quadra'),
        (16, 'Ciencias da Natureza', 'energia eletrica em equipamentos domesticos'),
        (17, 'Ciencias da Natureza', 'ciclo da agua e impactos ambientais'),
        (18, 'Ciencias da Natureza', 'reacoes quimicas no tratamento de agua'),
        (19, 'Ciencias da Natureza', 'genetica mendeliana em heredograma'),
        (20, 'Ciencias da Natureza', 'conservacao de energia mecanica'),
        (21, 'Linguagens', 'argumentacao em artigo de opiniao'),
        (22, 'Linguagens', 'coesao textual em reportagem'),
        (23, 'Linguagens', 'linguagem corporal em pratica esportiva'),
        (24, 'Linguagens', 'genero textual carta aberta'),
        (25, 'Linguagens', 'analise de grafite como expressao urbana'),
        (26, 'Ciencias Humanas', 'globalizacao e redes de transporte'),
        (27, 'Ciencias Humanas', 'democracia ateniense e democracia moderna'),
        (28, 'Ciencias Humanas', 'movimentos sociais no Brasil republicano'),
        (29, 'Ciencias Humanas', 'cartografia e leitura de mapas'),
        (30, 'Ciencias Humanas', 'etica e responsabilidade coletiva'),
        (31, 'Matematica', 'porcentagem em desconto comercial'),
        (32, 'Matematica', 'progressao aritmetica em treino fisico'),
        (33, 'Matematica', 'volume de prismas em reservatorio'),
        (34, 'Matematica', 'escala em planta baixa'),
        (35, 'Matematica', 'analise combinatoria em senhas'),
        (36, 'Ciencias da Natureza', 'pH em produtos de limpeza'),
        (37, 'Ciencias da Natureza', 'cadeias alimentares em ecossistema costeiro'),
        (38, 'Ciencias da Natureza', 'ondas sonoras em sala de aula'),
        (39, 'Ciencias da Natureza', 'separacao de misturas em laboratorio'),
        (40, 'Ciencias da Natureza', 'vacinas e resposta imunologica'),
        (41, 'Linguagens', 'sentido figurado em cronica urbana'),
        (42, 'Ciencias Humanas', 'industrializacao tardia e desigualdade regional'),
        (43, 'Matematica', 'media ponderada em notas escolares'),
        (44, 'Ciencias da Natureza', 'fotossintese e fluxo de energia'),
        (45, 'Matematica', 'leitura de grafico sobre desempenho em simulados'),
        (46, 'Linguagens', 'estrategia persuasiva em discurso publico'),
        (47, 'Ciencias Humanas', 'migracoes internas e mercado de trabalho'),
        (48, 'Matematica', 'juros compostos em aplicacao financeira'),
        (49, 'Ciencias da Natureza', 'densidade e flutuacao de materiais'),
        (50, 'Linguagens', 'marcas de oralidade em entrevista')
)
insert into app.questoes (enunciado, alternativas, alternativa_correta)
select
    jsonb_build_object(
        'area', area,
        'tema', tema,
        'comando', 'Analise a situacao apresentada e selecione a alternativa mais adequada.'
    ),
    jsonb_build_array(
        'Alternativa A sobre ' || tema,
        'Alternativa B sobre ' || tema,
        'Alternativa C sobre ' || tema,
        'Alternativa D sobre ' || tema,
        'Alternativa E sobre ' || tema
    ),
    (((ordem - 1) % 5) + 1)::smallint
from temas
order by ordem;

create temporary table tmp_seed_sessoes (
    sessao_id uuid primary key,
    aluno_id uuid not null,
    iniciado_em timestamptz not null,
    questoes_apresentadas integer not null,
    respostas_inseridas integer not null,
    acertos_desejados integer not null,
    concluir boolean not null
) on commit drop;

insert into tmp_seed_sessoes values
    ('40100000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '2026-04-01 08:00:00-03', 50, 50, 45, true),
    ('40100000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', '2026-04-08 08:00:00-03', 50, 50, 44, true),
    ('40100000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', '2026-04-15 08:00:00-03', 50, 50, 43, true),
    ('40200000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', '2026-04-02 08:00:00-03', 50, 50, 45, true),
    ('40200000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', '2026-04-09 08:00:00-03', 50, 50, 43, true),
    ('40200000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000002', '2026-04-16 08:00:00-03', 40, 40, 36, true),
    ('40300000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', '2026-04-03 08:00:00-03', 50, 50, 45, true),
    ('40300000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', '2026-04-10 08:00:00-03', 40, 40, 35, true),
    ('40300000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', '2026-04-17 08:00:00-03', 40, 40, 35, true),
    ('40400000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000004', '2026-04-04 08:00:00-03', 50, 50, 42, true),
    ('40400000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000004', '2026-04-11 08:00:00-03', 40, 40, 35, true),
    ('40400000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000004', '2026-04-18 08:00:00-03', 30, 30, 26, true),
    ('40500000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000005', '2026-04-05 08:00:00-03', 40, 40, 36, true),
    ('40500000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000005', '2026-04-12 08:00:00-03', 40, 40, 35, true),
    ('40500000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000005', '2026-04-19 08:00:00-03', 30, 30, 25, true),
    ('40600000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000006', '2026-04-06 08:00:00-03', 35, 35, 31, true),
    ('40600000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000006', '2026-04-13 08:00:00-03', 35, 35, 30, true),
    ('40600000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000006', '2026-04-20 08:00:00-03', 35, 35, 29, true),
    ('40700000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000007', '2026-04-07 08:00:00-03', 30, 30, 30, true),
    ('40800000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000008', '2026-04-21 08:00:00-03', 15, 15, 9, true),
    ('40800000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000008', '2026-05-02 08:00:00-03', 10, 0, 0, false),
    ('41100000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000011', '2026-04-22 08:00:00-03', 20, 20, 10, true),
    ('41300000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000013', '2026-04-23 08:00:00-03', 25, 25, 12, true),
    ('41400000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000014', '2026-04-24 08:00:00-03', 12, 12, 8, true);

insert into app.sessoes_simulado (id, aluno_id, status, iniciado_em)
select
    sessao_id,
    aluno_id,
    'em_andamento'::app.status_sessao,
    iniciado_em
from tmp_seed_sessoes;

insert into app.sessao_questoes (sessao_id, questao_id, ordem, apresentada_em)
select
    ts.sessao_id,
    q.id,
    g.ordem,
    ts.iniciado_em + ((g.ordem || ' minutes')::interval)
from tmp_seed_sessoes ts
join lateral generate_series(1, ts.questoes_apresentadas) as g(ordem) on true
join app.questoes q
  on q.numero_identificacao = g.ordem;

insert into app.respostas_simulado (sessao_id, questao_id, alternativa_escolhida, respondido_em)
select
    ts.sessao_id,
    q.id,
    (
        case
            when g.ordem <= ts.acertos_desejados then q.alternativa_correta
            when q.alternativa_correta = 1 then 2
            else 1
        end
    )::smallint as alternativa_escolhida,
    ts.iniciado_em + (((g.ordem + 5) || ' minutes')::interval)
from tmp_seed_sessoes ts
join lateral generate_series(1, ts.respostas_inseridas) as g(ordem) on true
join app.questoes q
  on q.numero_identificacao = g.ordem;

update app.sessoes_simulado s
   set status = 'concluida'::app.status_sessao,
       finalizado_em = ts.iniciado_em + interval '2 hours'
  from tmp_seed_sessoes ts
 where ts.concluir = true
   and s.id = ts.sessao_id;

-- Caso controlado para a consulta de auditoria:
-- a sessao abaixo possui 15 respostas reais, mas o total armazenado foi
-- alterado para 16 para simular dessincronizacao dos totalizadores.
update app.sessoes_simulado
   set total_questoes_apresentadas = total_questoes_apresentadas + 1
 where id = '40800000-0000-0000-0000-000000000001';

commit;
