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
