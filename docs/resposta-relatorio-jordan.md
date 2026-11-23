# Resposta ao relatório de aprimoramentos

Análise · 13/11/2026, corrigida em 18/11/2026 · sobre o relatório "Aprimoramentos do aplicativo de atendimento ao cliente", de Jordan Neves de Lima, da mesma data.

**Correção de 18/11/2026:** o escritório não pediu atendimento por áudio; o item saiu desta análise. A contratação integrada entra na v2.0, só para o cliente dar início à abertura de um novo processo pelo app, com a jornada ainda a definir.

## Resumo

O relatório está alinhado com o produto e quase todas as propostas cabem nele. Elas se dividem em quatro grupos:

- **Ajustes que dá para fazer já no app,** sem servidor, em cerca de 1 a 1,5 semana. Inclui os erros de texto e de concordância que ele apontou e o preparo da demonstração que ele pede para a próxima reunião.
- **Informações novas por caso** (providências do escritório, data da última consulta ao tribunal, etapa explicada, estado do documento enviado). O app mostra; o servidor e o painel da v2 alimentam.
- **Perguntas vinculadas ao caso, com resposta no app.** É a prioridade 2 dele, e estava prevista só para depois do piloto. Proponho trazer para a v2.
- **Contratação integrada.** Entra na v2.0 como início da abertura de um novo processo pelo app; a jornada ainda será definida com o escritório.

Um ponto precisa ser dito com clareza na reunião: o relatório fala de "integrações informadas no contexto do projeto", inclusive com o WhatsApp para enviar contratos. Hoje o app é uma demonstração com dados de exemplo; nenhuma integração existe ainda. O WhatsApp é só um link que abre a conversa com a mensagem pronta.

## O que ele apontou e já se confirma no app

| Ponto do relatório | O que está no app | Correção |
| --- | --- | --- |
| "3 exige você", "1 encerrados" | Os textos não têm forma de singular e plural | Variações de plural no catálogo de textos |
| Alertas de locação nas abas Processos e Pessoais | A seção "Precisa de você" de Documentos não filtra pela aba | Filtrar pela categoria da aba |
| Dados de exemplo no Contato, "Jurídico empresarial" | Telefone, endereço e cidade de exemplo no `Brand.json` | Dados reais das unidades de ES e MS e as áreas atendidas (precisamos que ele envie) |
| Data trocada pela simples abertura da tela | A demonstração marca "atualizado hoje às 8h30" a cada abertura | Na demonstração, data fixa e um caso com "atualização pendente"; com o servidor, a data vem da última consulta bem-sucedida |
| Audiência e confirmação no mesmo lugar | O cartão diz "Audiência em … · confirme até …" numa linha só | Duas linhas rotuladas: "Audiência em" e "Confirme até" |
| "União contestou — resposta já em preparo", de outubro | Texto da demonstração de pessoa física, com data antiga | Reescrever a demonstração para não afirmar preparo sem atividade registrada |

## Classificação de todas as propostas

### Ajuste no app, já (sem servidor)

- [ ] "Exige você" → "Precisa da sua atenção", seguido da ação exata.
- [ ] "Nada a fazer" → "Nenhuma ação necessária da sua parte".
- [ ] Concordância de singular e plural em todas as contagens.
- [ ] Filtro de pendências pela categoria em Documentos.
- [ ] "Audiência em" e "Confirme até" separados.
- [ ] "Não consigo comparecer" → "Não poderei comparecer".
- [ ] "Ouvir esta atualização": leitura em voz da mesma explicação revisada, com a voz do próprio iPhone. Por ser o mesmo texto, áudio e texto não divergem.
- [ ] Teste de rolagem, conteúdo atrás da barra inferior, telas menores, fonte ampliada e VoiceOver, com correções.
- [ ] Demonstração preparada para a reunião (próxima seção).
- [ ] Contato com os dados reais, quando ele enviar.

Estimativa: 1 a 1,5 semana.

### Informação nova por caso (app mostra; servidor e painel da v2 alimentam)

Cada item vira campo novo no contrato da API (v1.1, sem quebrar o que existe) e, até o servidor existir, aparece com dados de demonstração.

| Proposta | Campo novo | Quem preenche |
| --- | --- | --- |
| Providências do escritório na linha do tempo (análise concluída, peça em revisão, protocolo) | Providência: tipo, situação, data, responsável | Equipe, no painel |
| Separar última movimentação, última consulta bem-sucedida e última análise da equipe | Três datas por caso | Conector (consulta) e painel (análise) |
| Explicar períodos sem novidade e o que se aguarda | "O que estamos aguardando", por caso | Equipe, no painel |
| Etapa concreta no lugar de "Com o tribunal" e "Em dia" | Etapa do processo, em texto revisado | Equipe, com modelos validados |
| Prazo de quem: cliente, escritório ou outra parte | Responsável pelo prazo | Equipe |
| Risco com avaliação validada, data, responsável e explicação | Avaliação de risco com metadados | Advogado responsável |
| Documento: Recebido, Em conferência, Aceito, Precisamos de outra versão | Estado do documento enviado | Equipe, no painel |
| "Não poderei comparecer" chegando à equipe | Rota para registrar o impedimento | App → servidor → fila da equipe |
| Preferências de notificação (pendências, atualizações relevantes, resumo) | Preferências por usuário | Cliente, no app |
| Painel destacando o que está parado | Filas: sem explicação, atividade parada, documento sem conferência, pergunta sem resposta, falha de sincronização | Servidor |
| Revisão vinculada à especialidade e ao responsável | Quem revisou, versão publicada | Painel |
| Distinguir leitura de cumprimento | "Lido" separado de "resolvido" nas pendências | Servidor |

Acréscimo estimado à v2: 1,5 a 2 semanas, entre app, servidor e painel.

### Perguntas vinculadas ao caso (prioridade 2 dele)

A pergunta nasce dentro do caso ou do documento, chega ao responsável com o contexto e a resposta fica no app. O WhatsApp continua como alternativa. Isso é a conversa que o escopo de 22/07/2026 tinha cortado e que o plano da v2 deixava para depois do piloto.

Proposta: trazer para a v2, sobre o mesmo servidor (tempo real do Supabase), e não pelo CloudKit, pelos motivos em [arquitetura-cloudkit-analise.md](arquitetura-cloudkit-analise.md). Acréscimo estimado: 3 a 4 semanas (tela no app, caixa de entrada no painel com responsável e prazo, notificações).

### Contratação integrada (v2.0, jornada a definir)

Na v2.0, a contratação integrada serve só para o cliente dar início à abertura de um novo processo pelo app. Quais dados o cliente informa, o que a equipe recebe e o que acontece depois ainda serão definidos com o escritório. Proposta, contrato e assinatura eletrônica dentro do app não fazem parte desse início: a assinatura saiu do escopo em 22/07/2026, e voltar exige escolher um serviço de assinatura.

Acréscimo à v2: a estimar depois de definida a jornada.

### Outras propostas, depois da v2

| Proposta | Prioridade dele | Observação |
| --- | ---: | --- |
| Aproveitamento do cadastro e conferência da procuração para a nova demanda | 3 | Liga-se à abertura de processo pelo app; depende de os dados do cliente estarem no servidor |
| Resumo periódico e acompanhamento preventivo de contratos | 4 | O alerta 60/30/7 já existe no app; o resumo periódico entra com as notificações da v2 |

## A demonstração da próxima reunião

Ele pede uma demonstração de ponta a ponta antes de ampliar o uso. Com o pacote de ajustes acima e cenários novos nos dados de demonstração, o app atual cobre a maior parte. O que depende do servidor precisa ser apresentado como plano, não como funcionamento.

| Cenário do relatório | Dá para demonstrar? |
| --- | --- |
| Processo sem novidade e consulta com falha | Sim, com os cenários novos na demonstração |
| Nova movimentação com a providência do escritório separada | Sim, com providências na demonstração |
| Documento enviado: recebimento, conferência, pedido de nova versão | Sim, com os estados na demonstração (a mudança de estado não acontece de verdade) |
| Audiência: confirmação e impedimento, prazo separado do evento | Em parte: a tela sim; o aviso chegando à equipe, não |
| Abertura de processo pelo app | Não: jornada ainda a definir |
| Cliente recorrente e procuração | Não: funcionalidade nova |
| Contrato: envio separado de assinatura | Não: fora do escopo atual |
| Acesso e revisão: cada cliente vê só o que é dele | Não de verdade: depende do servidor; dá para mostrar o desenho |
| Usabilidade: rolagem, fonte ampliada, telas menores | Sim |

## Efeito no plano da v2

As prioridades dele reorganizam [plano-v2.md](plano-v2.md):

| Ordem dele | Onde fica |
| --- | --- |
| 1. Situação confiável, trabalho da equipe visível, pendências claras, confirmação de envios | v2.0, com os campos novos acima |
| 2. Notificações relevantes e perguntas vinculadas ao caso | v2.0: notificações já estavam; perguntas passam a entrar |
| 3. Aproveitamento do cadastro | Depois da v2 |
| 4. Contratação integrada | v2.0, só o início da abertura de processo; jornada a definir |
| 4. Resumo periódico e contratos preventivos | Com as notificações da v2; resumo periódico depois |

Com os campos novos (1,5 a 2 semanas) e as perguntas no caso (3 a 4 semanas), a v2 passa de 13,5 a 18 para **18 a 24 semanas**, cerca de **R$ 108 mil a R$ 144 mil** a R$ 150 por hora, mais 20% de reserva. A abertura de processo pelo app não está nessa conta: entra quando a jornada for definida. São números internos, com premissas de mercado; não vão para material do escritório.

Medição: ele prefere não fixar metas numéricas antes de conhecer a linha de base. Os indicadores dele (pedidos de atualização, primeira resposta útil, documentos pedidos de novo, conclusão das tarefas, clareza percebida) substituem as metas numéricas do plano da v2, medidos antes e depois com clientes de perfis diferentes.

## O que perguntar a ele

1. Telefones, endereços e horários das unidades de ES e MS, e as áreas que o escritório atende, para o Contato e a frase de apresentação.
2. O que é "Visão" em "vincular explicações jurídicas à especialidade, ao Visão e ao responsável".
3. Quais integrações ele entende que já existem. Hoje nenhuma está ligada, e isso precisa estar claro antes da demonstração.
4. Se aceita trazer as perguntas no caso para a v2, com o acréscimo de prazo e custo.
5. Como deve ser a jornada de abertura de processo pelo app: o que o cliente informa, quem recebe na equipe e o que ele vê depois.
