-- Questao 3
-- Lista estudantes que nunca iniciaram uma sessao de simulado.
-- No schema da parte 1, role = 'student' corresponde a papel = 'aluno'.

select
    p.nome_completo,
    p.usuario_id as id_usuario
from app.perfis p
where p.papel = 'aluno'
  and not exists (
      select 1
      from app.sessoes_simulado s
      where s.aluno_id = p.usuario_id
  )
order by p.nome_completo;
