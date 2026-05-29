-- Questao 4
-- Retorna aluno, alternativa escolhida e se acertou para respostas da
-- questao 45, somente de alunos matriculados na escola de CNPJ informado.
--
-- O schema guarda CNPJ somente com digitos. Por isso a comparacao normaliza
-- tanto o valor armazenado quanto o valor recebido no formato do enunciado.

select
    p.nome_completo as aluno,
    r.alternativa_escolhida,
    r.acertou as is_correct
from app.respostas_simulado r
join app.sessoes_simulado s
  on s.id = r.sessao_id
join app.perfis p
  on p.usuario_id = s.aluno_id
join app.questoes q
  on q.id = r.questao_id
join app.matriculas m
  on m.aluno_id = p.usuario_id
join app.escolas e
  on e.id = m.escola_id
where q.numero_identificacao = 45
  and regexp_replace(e.cnpj, '[^0-9]', '', 'g') =
      regexp_replace('12.345.678/0001-99', '[^0-9]', '', 'g')
order by p.nome_completo, r.respondido_em;
