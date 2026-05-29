-- Questao 7
-- Lista os 5 alunos com maior numero absoluto de respostas corretas,
-- considerando apenas alunos com pelo menos 100 respostas em sessoes
-- concluidas.

select
    p.nome_completo,
    count(r.id) filter (where r.acertou = true)::integer as total_acertos,
    count(r.id)::integer as total_respostas
from app.perfis p
join app.sessoes_simulado s
  on s.aluno_id = p.usuario_id
 and s.status = 'concluida'
join app.respostas_simulado r
  on r.sessao_id = s.id
where p.papel = 'aluno'
group by p.usuario_id, p.nome_completo
having count(r.id) >= 100
order by total_acertos desc, p.nome_completo
limit 5;
