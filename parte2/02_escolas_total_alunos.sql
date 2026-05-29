-- Questao 2
-- Lista o nome das escolas cadastradas e a quantidade total de alunos
-- vinculados a cada uma delas, da maior quantidade para a menor.

select
    e.nome as escola,
    count(m.aluno_id)::integer as total_alunos
from app.escolas e
left join app.matriculas m
  on m.escola_id = e.id
group by e.id, e.nome
order by total_alunos desc, e.nome;
