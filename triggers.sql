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
