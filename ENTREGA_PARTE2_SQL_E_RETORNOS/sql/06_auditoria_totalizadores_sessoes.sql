-- Questao 6
-- Identifica sessoes concluidas com divergencia entre totalizadores
-- armazenados e os valores reais calculados pela tabela de respostas.

with totais_reais as (
    select
        r.sessao_id,
        count(r.id)::integer as contagem_real_respostas,
        count(r.id) filter (where r.acertou = true)::integer as contagem_real_acertos
    from app.respostas_simulado r
    group by r.sessao_id
)
select
    s.id as sessao_id,
    s.total_questoes_apresentadas as total_questions_armazenado,
    coalesce(tr.contagem_real_respostas, 0) as contagem_real_respostas,
    s.total_acertos as correct_count_armazenado,
    coalesce(tr.contagem_real_acertos, 0) as contagem_real_acertos
from app.sessoes_simulado s
left join totais_reais tr
  on tr.sessao_id = s.id
where s.status = 'concluida'
  and (
      s.total_questoes_apresentadas <> coalesce(tr.contagem_real_respostas, 0)
      or s.total_acertos <> coalesce(tr.contagem_real_acertos, 0)
  )
order by s.id;
