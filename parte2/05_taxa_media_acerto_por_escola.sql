-- Questao 5
-- Calcula a taxa global de acerto por escola considerando apenas sessoes
-- concluidas. A taxa usa respostas reais: total de acertos / total de
-- questoes respondidas.

select
    e.nome as escola,
    count(r.id)::integer as total_questoes_respondidas,
    count(r.id) filter (where r.acertou = true)::integer as total_acertos,
    round(
        100.0 * count(r.id) filter (where r.acertou = true) / nullif(count(r.id), 0),
        2
    ) as percentual_acerto
from app.escolas e
join app.matriculas m
  on m.escola_id = e.id
join app.sessoes_simulado s
  on s.aluno_id = m.aluno_id
 and s.status = 'concluida'
join app.respostas_simulado r
  on r.sessao_id = s.id
group by e.id, e.nome
having count(r.id) > 0
order by percentual_acerto desc, e.nome;
