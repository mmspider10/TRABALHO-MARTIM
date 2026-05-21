create extension if not exists pgcrypto;

create schema if not exists auth;
create schema if not exists app;

do $$
begin
    create type app.papel_usuario as enum (
        'aluno',
        'administrador_escolar',
        'administrador_global'
    );
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type app.status_sessao as enum (
        'em_andamento',
        'concluida'
    );
exception
    when duplicate_object then null;
end
$$;

create table if not exists auth.usuarios (
    id uuid primary key default gen_random_uuid(),
    email text not null unique,
    nome_completo text not null,
    papel_inicial app.papel_usuario,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint auth_usuarios_email_chk check (position('@' in email) > 1)
);

create table if not exists app.perfis (
    usuario_id uuid primary key references auth.usuarios(id) on delete cascade,
    nome_completo text not null,
    papel app.papel_usuario not null default 'aluno',
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now()
);

create table if not exists app.escolas (
    id uuid primary key default gen_random_uuid(),
    nome text not null,
    cnpj text not null unique,
    administrador_escolar_id uuid not null references app.perfis(usuario_id),
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint escolas_cnpj_chk check (cnpj ~ '^[0-9]{14}$')
);

create table if not exists app.matriculas (
    id uuid primary key default gen_random_uuid(),
    escola_id uuid not null references app.escolas(id) on delete cascade,
    aluno_id uuid not null references app.perfis(usuario_id) on delete cascade,
    data_matricula date not null default current_date,
    criado_em timestamptz not null default now(),
    constraint matriculas_escola_aluno_uk unique (escola_id, aluno_id)
);

create table if not exists app.questoes (
    id uuid primary key default gen_random_uuid(),
    numero_identificacao bigint generated always as identity,
    enunciado jsonb not null,
    alternativas jsonb not null,
    alternativa_correta smallint not null,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint questoes_numero_identificacao_uk unique (numero_identificacao),
    constraint questoes_alternativas_tipo_chk check (jsonb_typeof(alternativas) = 'array'),
    constraint questoes_alternativas_tamanho_chk check (jsonb_array_length(alternativas) >= 2),
    constraint questoes_alternativa_correta_chk check (
        alternativa_correta between 1 and jsonb_array_length(alternativas)
    )
);

create table if not exists app.sessoes_simulado (
    id uuid primary key default gen_random_uuid(),
    aluno_id uuid not null references app.perfis(usuario_id) on delete cascade,
    status app.status_sessao not null default 'em_andamento',
    iniciado_em timestamptz not null default now(),
    finalizado_em timestamptz,
    total_questoes_apresentadas integer not null default 0,
    total_acertos integer not null default 0,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint sessoes_totais_chk check (
        total_questoes_apresentadas >= 0
        and total_acertos >= 0
        and total_acertos <= total_questoes_apresentadas
    ),
    constraint sessoes_status_datas_chk check (
        (
            status = 'em_andamento'
            and finalizado_em is null
        )
        or (
            status = 'concluida'
            and finalizado_em is not null
            and finalizado_em >= iniciado_em
        )
    )
);

create table if not exists app.sessao_questoes (
    id uuid primary key default gen_random_uuid(),
    sessao_id uuid not null references app.sessoes_simulado(id) on delete cascade,
    questao_id uuid not null references app.questoes(id) on delete cascade,
    ordem integer not null,
    apresentada_em timestamptz not null default now(),
    constraint sessao_questoes_ordem_chk check (ordem > 0),
    constraint sessao_questoes_sessao_questao_uk unique (sessao_id, questao_id),
    constraint sessao_questoes_sessao_ordem_uk unique (sessao_id, ordem)
);

create table if not exists app.respostas_simulado (
    id uuid primary key default gen_random_uuid(),
    sessao_id uuid not null,
    questao_id uuid not null,
    alternativa_escolhida smallint not null,
    acertou boolean not null default false,
    respondido_em timestamptz not null default now(),
    constraint respostas_alternativa_escolhida_chk check (alternativa_escolhida > 0),
    constraint respostas_sessao_questao_uk unique (sessao_id, questao_id),
    constraint respostas_sessao_questao_fk
        foreign key (sessao_id, questao_id)
        references app.sessao_questoes(sessao_id, questao_id)
        on delete cascade
);

create index if not exists idx_perfis_papel
    on app.perfis (papel);

create index if not exists idx_escolas_administrador
    on app.escolas (administrador_escolar_id);

create index if not exists idx_matriculas_aluno
    on app.matriculas (aluno_id);

create index if not exists idx_matriculas_escola
    on app.matriculas (escola_id);

create index if not exists idx_sessoes_aluno_status
    on app.sessoes_simulado (aluno_id, status);

create index if not exists idx_sessao_questoes_sessao
    on app.sessao_questoes (sessao_id);

create index if not exists idx_respostas_sessao
    on app.respostas_simulado (sessao_id);

create index if not exists idx_respostas_questao
    on app.respostas_simulado (questao_id);
