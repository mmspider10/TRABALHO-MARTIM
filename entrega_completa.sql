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

create or replace function app.fn_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.atualizado_em = now();
    return new;
end;
$$;

create or replace function app.fn_inicializar_perfil_usuario()
returns trigger
language plpgsql
as $$
begin
    insert into app.perfis (usuario_id, nome_completo, papel)
    values (
        new.id,
        new.nome_completo,
        coalesce(new.papel_inicial, 'aluno')
    );

    return new;
end;
$$;

create or replace function app.fn_sincronizar_nome_perfil()
returns trigger
language plpgsql
as $$
begin
    update app.perfis
       set nome_completo = new.nome_completo,
           atualizado_em = now()
     where usuario_id = new.id;

    return new;
end;
$$;

create or replace function app.fn_validar_admin_escolar()
returns trigger
language plpgsql
as $$
declare
    v_papel app.papel_usuario;
begin
    select papel
      into v_papel
      from app.perfis
     where usuario_id = new.administrador_escolar_id;

    if v_papel is distinct from 'administrador_escolar' then
        raise exception 'O responsavel da escola deve possuir o papel administrador_escolar.';
    end if;

    return new;
end;
$$;

create or replace function app.fn_validar_matricula_aluno()
returns trigger
language plpgsql
as $$
declare
    v_papel app.papel_usuario;
begin
    select papel
      into v_papel
      from app.perfis
     where usuario_id = new.aluno_id;

    if v_papel is distinct from 'aluno' then
        raise exception 'A matricula so pode ser criada para perfis com papel aluno.';
    end if;

    return new;
end;
$$;

create or replace function app.fn_validar_sessao_aluno()
returns trigger
language plpgsql
as $$
declare
    v_papel app.papel_usuario;
begin
    select papel
      into v_papel
      from app.perfis
     where usuario_id = new.aluno_id;

    if v_papel is distinct from 'aluno' then
        raise exception 'Somente usuarios com papel aluno podem iniciar sessoes de simulado.';
    end if;

    return new;
end;
$$;

create or replace function app.fn_validar_troca_papel_perfil()
returns trigger
language plpgsql
as $$
begin
    if new.papel = old.papel then
        return new;
    end if;

    if exists (
        select 1
          from app.escolas e
         where e.administrador_escolar_id = old.usuario_id
    ) and new.papel <> 'administrador_escolar' then
        raise exception 'Nao e possivel remover o papel de administrador_escolar de um perfil que administra escolas.';
    end if;

    if exists (
        select 1
          from app.matriculas m
         where m.aluno_id = old.usuario_id
    ) and new.papel <> 'aluno' then
        raise exception 'Nao e possivel remover o papel de aluno de um perfil matriculado em escolas.';
    end if;

    if exists (
        select 1
          from app.sessoes_simulado s
         where s.aluno_id = old.usuario_id
    ) and new.papel <> 'aluno' then
        raise exception 'Nao e possivel remover o papel de aluno de um perfil com sessoes de simulado registradas.';
    end if;

    return new;
end;
$$;

create or replace function app.fn_preparar_resposta_simulado()
returns trigger
language plpgsql
as $$
declare
    v_status app.status_sessao;
    v_alternativa_correta smallint;
    v_total_alternativas integer;
begin
    select s.status
      into v_status
      from app.sessoes_simulado s
     where s.id = new.sessao_id;

    if v_status is distinct from 'em_andamento' then
        raise exception 'Nao e permitido registrar respostas em sessoes concluidas.';
    end if;

    select q.alternativa_correta,
           jsonb_array_length(q.alternativas)
      into v_alternativa_correta,
           v_total_alternativas
      from app.sessao_questoes sq
      join app.questoes q
        on q.id = sq.questao_id
     where sq.sessao_id = new.sessao_id
       and sq.questao_id = new.questao_id;

    if v_total_alternativas is null then
        raise exception 'A questao precisa estar previamente vinculada a sessao.';
    end if;

    if new.alternativa_escolhida > v_total_alternativas then
        raise exception 'A alternativa escolhida excede o total de alternativas da questao.';
    end if;

    new.acertou = (new.alternativa_escolhida = v_alternativa_correta);
    return new;
end;
$$;

create or replace function app.fn_recalcular_resumo_sessao(p_sessao_id uuid)
returns void
language plpgsql
as $$
begin
    update app.sessoes_simulado s
       set total_questoes_apresentadas = (
               select count(*)
                 from app.sessao_questoes sq
                where sq.sessao_id = p_sessao_id
           ),
           total_acertos = (
               select count(*)
                 from app.respostas_simulado r
                where r.sessao_id = p_sessao_id
                  and r.acertou = true
           ),
           atualizado_em = now()
     where s.id = p_sessao_id;
end;
$$;

create or replace function app.fn_atualizar_resumo_sessao_trigger()
returns trigger
language plpgsql
as $$
declare
    v_sessao_id uuid;
begin
    if tg_op = 'DELETE' then
        v_sessao_id = old.sessao_id;
    else
        v_sessao_id = new.sessao_id;
    end if;

    perform app.fn_recalcular_resumo_sessao(v_sessao_id);

    if tg_op = 'UPDATE'
       and new.sessao_id is distinct from old.sessao_id then
        perform app.fn_recalcular_resumo_sessao(old.sessao_id);
    end if;

    return null;
end;
$$;

drop trigger if exists trg_auth_usuarios_touch_updated_at on auth.usuarios;
create trigger trg_auth_usuarios_touch_updated_at
before update on auth.usuarios
for each row
execute function app.fn_touch_updated_at();

drop trigger if exists trg_auth_usuarios_inicializar_perfil on auth.usuarios;
create trigger trg_auth_usuarios_inicializar_perfil
after insert on auth.usuarios
for each row
execute function app.fn_inicializar_perfil_usuario();

drop trigger if exists trg_auth_usuarios_sincronizar_nome_perfil on auth.usuarios;
create trigger trg_auth_usuarios_sincronizar_nome_perfil
after update of nome_completo on auth.usuarios
for each row
execute function app.fn_sincronizar_nome_perfil();

drop trigger if exists trg_perfis_touch_updated_at on app.perfis;
create trigger trg_perfis_touch_updated_at
before update on app.perfis
for each row
execute function app.fn_touch_updated_at();

drop trigger if exists trg_perfis_validar_troca_papel on app.perfis;
create trigger trg_perfis_validar_troca_papel
before update of papel on app.perfis
for each row
execute function app.fn_validar_troca_papel_perfil();

drop trigger if exists trg_escolas_touch_updated_at on app.escolas;
create trigger trg_escolas_touch_updated_at
before update on app.escolas
for each row
execute function app.fn_touch_updated_at();

drop trigger if exists trg_escolas_validar_admin on app.escolas;
create trigger trg_escolas_validar_admin
before insert or update of administrador_escolar_id on app.escolas
for each row
execute function app.fn_validar_admin_escolar();

drop trigger if exists trg_matriculas_validar_aluno on app.matriculas;
create trigger trg_matriculas_validar_aluno
before insert or update of aluno_id on app.matriculas
for each row
execute function app.fn_validar_matricula_aluno();

drop trigger if exists trg_questoes_touch_updated_at on app.questoes;
create trigger trg_questoes_touch_updated_at
before update on app.questoes
for each row
execute function app.fn_touch_updated_at();

drop trigger if exists trg_sessoes_touch_updated_at on app.sessoes_simulado;
create trigger trg_sessoes_touch_updated_at
before update on app.sessoes_simulado
for each row
execute function app.fn_touch_updated_at();

drop trigger if exists trg_sessoes_validar_aluno on app.sessoes_simulado;
create trigger trg_sessoes_validar_aluno
before insert or update of aluno_id on app.sessoes_simulado
for each row
execute function app.fn_validar_sessao_aluno();

drop trigger if exists trg_respostas_preparar on app.respostas_simulado;
create trigger trg_respostas_preparar
before insert or update on app.respostas_simulado
for each row
execute function app.fn_preparar_resposta_simulado();

drop trigger if exists trg_sessao_questoes_recalcular_resumo on app.sessao_questoes;
create trigger trg_sessao_questoes_recalcular_resumo
after insert or update or delete on app.sessao_questoes
for each row
execute function app.fn_atualizar_resumo_sessao_trigger();

drop trigger if exists trg_respostas_recalcular_resumo on app.respostas_simulado;
create trigger trg_respostas_recalcular_resumo
after insert or update or delete on app.respostas_simulado
for each row
execute function app.fn_atualizar_resumo_sessao_trigger();

create or replace function app.current_user_id()
returns uuid
language sql
stable
as $$
    select nullif(current_setting('app.current_user_id', true), '')::uuid;
$$;

create or replace function app.current_user_papel()
returns app.papel_usuario
language sql
stable
security definer
set search_path = app, auth, public
as $$
    select p.papel
      from app.perfis p
     where p.usuario_id = app.current_user_id();
$$;

create or replace function app.is_authenticated()
returns boolean
language sql
stable
as $$
    select app.current_user_id() is not null;
$$;

create or replace function app.is_admin_global()
returns boolean
language sql
stable
security definer
set search_path = app, auth, public
as $$
    select exists (
        select 1
          from app.perfis p
         where p.usuario_id = app.current_user_id()
           and p.papel = 'administrador_global'
    );
$$;

create or replace function app.is_admin_escolar()
returns boolean
language sql
stable
security definer
set search_path = app, auth, public
as $$
    select exists (
        select 1
          from app.perfis p
         where p.usuario_id = app.current_user_id()
           and p.papel = 'administrador_escolar'
    );
$$;

create or replace function app.user_administra_escola(p_escola_id uuid)
returns boolean
language sql
stable
security definer
set search_path = app, auth, public
as $$
    select exists (
        select 1
          from app.escolas e
         where e.id = p_escola_id
           and e.administrador_escolar_id = app.current_user_id()
    );
$$;

create or replace function app.user_esta_matriculado_na_escola(p_escola_id uuid)
returns boolean
language sql
stable
security definer
set search_path = app, auth, public
as $$
    select exists (
        select 1
          from app.matriculas m
         where m.escola_id = p_escola_id
           and m.aluno_id = app.current_user_id()
    );
$$;

create or replace function app.user_administra_aluno(p_aluno_id uuid)
returns boolean
language sql
stable
security definer
set search_path = app, auth, public
as $$
    select exists (
        select 1
          from app.matriculas m
          join app.escolas e
            on e.id = m.escola_id
         where m.aluno_id = p_aluno_id
           and e.administrador_escolar_id = app.current_user_id()
    );
$$;

alter table app.perfis enable row level security;
alter table app.escolas enable row level security;
alter table app.matriculas enable row level security;
alter table app.questoes enable row level security;
alter table app.sessoes_simulado enable row level security;
alter table app.sessao_questoes enable row level security;
alter table app.respostas_simulado enable row level security;

drop policy if exists perfis_select on app.perfis;
create policy perfis_select
on app.perfis
for select
using (
    usuario_id = app.current_user_id()
    or app.is_admin_global()
    or app.user_administra_aluno(usuario_id)
);

drop policy if exists perfis_update on app.perfis;
create policy perfis_update
on app.perfis
for update
using (
    usuario_id = app.current_user_id()
    or app.is_admin_global()
    or app.user_administra_aluno(usuario_id)
)
with check (
    usuario_id = app.current_user_id()
    or app.is_admin_global()
    or app.user_administra_aluno(usuario_id)
);

drop policy if exists perfis_insert on app.perfis;
create policy perfis_insert
on app.perfis
for insert
with check (
    app.is_admin_global()
);

drop policy if exists perfis_delete on app.perfis;
create policy perfis_delete
on app.perfis
for delete
using (
    app.is_admin_global()
);

drop policy if exists escolas_select on app.escolas;
create policy escolas_select
on app.escolas
for select
using (
    app.is_admin_global()
    or app.user_administra_escola(id)
    or app.user_esta_matriculado_na_escola(id)
);

drop policy if exists escolas_insert on app.escolas;
create policy escolas_insert
on app.escolas
for insert
with check (
    app.is_admin_global()
);

drop policy if exists escolas_update on app.escolas;
create policy escolas_update
on app.escolas
for update
using (
    app.is_admin_global()
    or app.user_administra_escola(id)
)
with check (
    app.is_admin_global()
    or app.user_administra_escola(id)
);

drop policy if exists escolas_delete on app.escolas;
create policy escolas_delete
on app.escolas
for delete
using (
    app.is_admin_global()
);

drop policy if exists matriculas_select on app.matriculas;
create policy matriculas_select
on app.matriculas
for select
using (
    app.is_admin_global()
    or aluno_id = app.current_user_id()
    or app.user_administra_escola(escola_id)
);

drop policy if exists matriculas_insert on app.matriculas;
create policy matriculas_insert
on app.matriculas
for insert
with check (
    app.is_admin_global()
    or app.user_administra_escola(escola_id)
);

drop policy if exists matriculas_update on app.matriculas;
create policy matriculas_update
on app.matriculas
for update
using (
    app.is_admin_global()
    or app.user_administra_escola(escola_id)
)
with check (
    app.is_admin_global()
    or app.user_administra_escola(escola_id)
);

drop policy if exists matriculas_delete on app.matriculas;
create policy matriculas_delete
on app.matriculas
for delete
using (
    app.is_admin_global()
    or app.user_administra_escola(escola_id)
);

drop policy if exists questoes_select on app.questoes;
create policy questoes_select
on app.questoes
for select
using (
    app.is_authenticated()
);

drop policy if exists questoes_insert on app.questoes;
create policy questoes_insert
on app.questoes
for insert
with check (
    app.is_admin_global()
);

drop policy if exists questoes_update on app.questoes;
create policy questoes_update
on app.questoes
for update
using (
    app.is_admin_global()
)
with check (
    app.is_admin_global()
);

drop policy if exists questoes_delete on app.questoes;
create policy questoes_delete
on app.questoes
for delete
using (
    app.is_admin_global()
);

drop policy if exists sessoes_select on app.sessoes_simulado;
create policy sessoes_select
on app.sessoes_simulado
for select
using (
    app.is_admin_global()
    or aluno_id = app.current_user_id()
    or app.user_administra_aluno(aluno_id)
);

drop policy if exists sessoes_insert on app.sessoes_simulado;
create policy sessoes_insert
on app.sessoes_simulado
for insert
with check (
    app.is_admin_global()
    or aluno_id = app.current_user_id()
);

drop policy if exists sessoes_update on app.sessoes_simulado;
create policy sessoes_update
on app.sessoes_simulado
for update
using (
    app.is_admin_global()
    or aluno_id = app.current_user_id()
)
with check (
    app.is_admin_global()
    or aluno_id = app.current_user_id()
);

drop policy if exists sessoes_delete on app.sessoes_simulado;
create policy sessoes_delete
on app.sessoes_simulado
for delete
using (
    app.is_admin_global()
    or aluno_id = app.current_user_id()
);

drop policy if exists sessao_questoes_select on app.sessao_questoes;
create policy sessao_questoes_select
on app.sessao_questoes
for select
using (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
               or app.user_administra_aluno(s.aluno_id)
           )
    )
);

drop policy if exists sessao_questoes_insert on app.sessao_questoes;
create policy sessao_questoes_insert
on app.sessao_questoes
for insert
with check (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
);

drop policy if exists sessao_questoes_update on app.sessao_questoes;
create policy sessao_questoes_update
on app.sessao_questoes
for update
using (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
)
with check (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
);

drop policy if exists sessao_questoes_delete on app.sessao_questoes;
create policy sessao_questoes_delete
on app.sessao_questoes
for delete
using (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
);

drop policy if exists respostas_select on app.respostas_simulado;
create policy respostas_select
on app.respostas_simulado
for select
using (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
               or app.user_administra_aluno(s.aluno_id)
           )
    )
);

drop policy if exists respostas_insert on app.respostas_simulado;
create policy respostas_insert
on app.respostas_simulado
for insert
with check (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
);

drop policy if exists respostas_update on app.respostas_simulado;
create policy respostas_update
on app.respostas_simulado
for update
using (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
)
with check (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
);

drop policy if exists respostas_delete on app.respostas_simulado;
create policy respostas_delete
on app.respostas_simulado
for delete
using (
    exists (
        select 1
          from app.sessoes_simulado s
         where s.id = sessao_id
           and (
               app.is_admin_global()
               or s.aluno_id = app.current_user_id()
           )
    )
);
