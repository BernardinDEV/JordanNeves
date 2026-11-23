# Quanto vale o app para um escritório

Estimativa · 11/11/2026. Os números saem de premissas a medir no escritório; leia como ordem de grandeza.

## Resumo

Para um escritório com 50 empresas clientes usando o app, o valor líquido estimado fica perto de **R$ 5 mil por mês**: cerca de R$ 1,8 mil com 20 clientes e R$ 10 mil com 100. Um preço de **R$ 990 por mês** para a faixa de 50 clientes, mais uma implantação de R$ 6 mil a R$ 12 mil, deixa uns 80% desse valor com o escritório.

Três coisas sustentam o número, e todas são premissas a confirmar com o escritório, não fatos medidos:

- quantas vezes por mês cada cliente liga ou manda mensagem para saber do processo;
- quanto tempo a equipe leva para revisar cada tradução;
- o honorário mensal médio de um cliente, que define quanto vale não perdê-lo.

O tempo poupado em atendimento é quase todo consumido pela revisão das traduções. O que sobra de valor vem sobretudo de reter clientes e de diferenciar o escritório, e por isso o preço deve ser vendido como retenção, não como economia de horas.

## De onde vem o valor

O app gera valor de duas formas, horas de atendimento poupadas e clientes retidos, e custa uma: o tempo da equipe revisando traduções.

**Com 50 clientes no app, sobram cerca de R$ 5 mil por mês:**

| Componente (por mês) | Valor | Saldo acumulado |
| --- | ---: | ---: |
| Tempo poupado em atendimento | + R$ 7.297 | R$ 7.297 |
| Revisão das traduções | − R$ 4.865 | R$ 2.432 |
| Clientes retidos | + R$ 3.000 | R$ 5.432 |
| Hospedagem e Apple | − R$ 400 | R$ 5.032 |
| **Valor líquido** | | **R$ 5.032** |

A revisão das traduções consome dois terços do tempo que o app poupa. Sem um bom rascunho automático e uma fila rápida, o ganho de horas desaparece, e o saldo passa a depender só da retenção.

| Premissa | Valor usado | De onde vem |
| --- | --- | --- |
| Contatos "como está meu processo?" por cliente | 3 por mês | Estimativa — medir no escritório |
| Duração de cada contato, com a busca da informação | 15 min | Estimativa |
| Contatos que o app evita | 60% | Estimativa |
| Andamentos a traduzir por cliente | 6 por mês | Estimativa: uns 3 processos com 2 andamentos cada |
| Revisão de cada tradução, partindo de rascunho automático | 3 min | Estudo de implementação do projeto |
| Valor da hora | R$ 324,33 | Tabela OAB-ES: consulta = 1,5 URH; URH = R$ 216,22 em outubro de 2026 |
| Honorário mensal médio por empresa cliente | R$ 3.000 | Estimativa — confirmar |
| Clientes que o app ajuda a não perder | 2% da carteira por ano | Estimativa |
| Hospedagem e conta Apple | R$ 400 por mês | Aproximado; Apple cobra US$ 99 por ano |

Como as contas fecham, com 50 clientes:

- Tempo poupado: 50 × 3 contatos × 60% × 15 min = 22,5 h × R$ 324,33 = R$ 7.297.
- Revisão: 50 × 6 andamentos × 3 min = 15 h × R$ 324,33 = R$ 4.865.
- Retenção: 2% de 50 clientes = 1 cliente por ano × R$ 3.000 × 12 meses = R$ 36.000 por ano, ou R$ 3.000 por mês.

Não entra na conta o que o app vale para o cliente do escritório, como um contrato que deixa de renovar sozinho por falta de aviso. É o argumento de venda mais forte, mas não é dinheiro que entra no escritório.

## Quanto custa entregar

O app está pronto; o que falta construir uma vez é o servidor, o conector e o painel da equipe, e cada escritório novo custa umas duas a três semanas de implantação.

| Item | Quando | Quanto | Quem paga |
| --- | --- | --- | --- |
| Servidor, conector Projuris e painel da equipe | Uma vez, para o produto | 10 a 14 semanas-pessoa | Nós (investimento do produto) |
| Implantação: marca, publicação na loja, conexão com o Projuris, treino da fila | Uma vez por escritório | 2 a 3 semanas | Escritório, pela taxa de implantação |
| Conta Apple Developer, em nome do escritório | Por ano | US$ 99 | Escritório |
| Hospedagem (banco, arquivos, notificações) | Por mês | cerca de R$ 300 | Nós, dentro da mensalidade |
| API do Projuris | Por mês | Depende do plano; o Projuris não publica preço | Escritório |
| Revisão das traduções | Todo dia | Tempo de advogado (está na conta acima) | Escritório |

As semanas vêm do estudo de implementação do projeto (painel da equipe 5 a 7, ingestão de andamentos 3 a 5, o restante de servidor), descontado o que o app já entrega. São ordem de grandeza, não orçamento.

O custo que mais pesa não aparece em fatura nenhuma: a rotina diária de revisar traduções. Se o escritório não assumir essa rotina, nada é publicado e o app fica vazio.

## Cenários por tamanho de escritório

O valor cresce quase em linha com o número de empresas clientes no app; a mensalidade sugerida fica entre 17% e 28% dele em todas as faixas.

| Empresas clientes no app | Valor líquido estimado por mês | Mensalidade sugerida | Fica com o escritório |
| ---: | ---: | ---: | ---: |
| 20 | R$ 1.773 | R$ 490 | 72% |
| 50 | R$ 5.032 | R$ 990 | 80% |
| 100 | R$ 10.265 | R$ 1.790 | 83% |

Mesmas premissas da tabela acima, com hospedagem de R$ 600 na faixa de 100 clientes.

O resultado é sensível a duas premissas, e as duas precisam ser medidas antes de fechar preço:

- **Contatos de status:** se cada cliente procura o escritório uma vez por mês, e não três, o ganho de horas não paga a revisão das traduções, e o valor líquido da faixa de 50 cai para perto de zero.
- **Honorário médio:** com R$ 5.000 por cliente em vez de R$ 3.000, a retenção sobe de R$ 3.000 para R$ 5.000 por mês, e o valor da faixa de 50 passa de R$ 7 mil.

## Como cobrar

Recomendo **implantação de R$ 6 mil a R$ 12 mil mais mensalidade por faixa de empresas clientes** (R$ 490, R$ 990 ou R$ 1.790). A implantação cobre as duas a três semanas de cada escritório, a R$ 3 mil a R$ 4 mil por semana de trabalho, valor que é premissa nossa.

Três formas de cobrar, da recomendada para as alternativas:

1. **Faixa de empresas clientes no app.** Previsível para o escritório e acompanha o valor gerado, que cresce com o número de clientes.
2. **Por empresa cliente ativa,** em torno de R$ 20 por mês. Escala sozinho, mas a fatura muda todo mês.
3. **Repassado ao cliente final** dentro do honorário. R$ 20 sobre um honorário de R$ 3.000 é menos de 1%, e o app vira argumento do escritório na hora de renovar o contrato.

O que o mercado cobra hoje, para comparar:

| Plano Astrea | Preço cheio por mês, no anual | Com o desconto de novembro | Processos monitorados | Usuários |
| --- | ---: | ---: | ---: | ---: |
| Up | R$ 249 | R$ 149 | 150 | 2 |
| Smart | R$ 439 | R$ 263 | 500 | 5 |
| Company | R$ 769 | R$ 461 | 1.000 | 10 |
| Vip | R$ 1.379 | R$ 827 | 2.000 | 30 |

Preços da página de planos do Astrea, lida em 11/11/2026; o preço cheio é o anual sem desconto dividido por 12. O Projuris não publica o preço do plano completo: é por proposta comercial.

O concorrente direto já entrega o básico. A tabela de recursos do Astrea traz "Aplicativo Portal do Cliente" e "Tradução do juridiquês com IA", dentro de um sistema de gestão completo. Por isso o preço não se sustenta como "app do cliente"; ele se sustenta no que é só deste produto:

- app com a marca do próprio escritório na loja;
- tradução revisada e aprovada por advogado antes de chegar ao cliente;
- separação entre "exige você" e "para saber", com push só para o primeiro;
- alerta de contratos em 60, 30 e 7 dias, contados do prazo de aviso prévio.

## Premissas e como validar

Duas semanas de medição no escritório trocam as estimativas por números reais; até lá, trate o valor como ordem de grandeza.

- [ ] **Contatos de status:** anotar por duas semanas cada ligação ou mensagem de cliente perguntando de processo, e quanto tempo levou para responder.
- [ ] **Honorário e perda de clientes:** honorário mensal médio das empresas clientes e quantas saíram nos últimos dois anos, e por quê.
- [ ] **Tamanho da carteira:** quantas empresas têm processo ativo hoje, e quantos andamentos por mês chegam em média.
- [ ] **Tempo de tradução:** cronometrar a revisão de 20 andamentos reais com rascunho automático.
- [ ] **Custo da API do Projuris** no plano do escritório.
- [ ] **Piloto:** ligar o app para dois ou três clientes por um mês e medir se os contatos de status caem.

O valor da hora usa a referência mínima da OAB-ES para consulta. Se quem responde ao cliente é um assistente, e não um advogado, o ganho de horas cai, e o preço precisa se apoiar ainda mais na retenção.

## Fontes

- [Planos e preços do Astrea](https://www.aurum.com.br/astrea/planos-e-precos/) — preços, limites e recursos dos planos, lida em 11/11/2026.
- [Projuris ADV](https://www.projuris.com.br/adv/?=start) — planos Start e completo; preço do completo por proposta.
- [Tabela de honorários OAB-ES 2026](https://toexceed.com.br/blog/2026/10/31/tabela-de-honorarios-oab-es-2026-valores-urh-consulta-divorcio-e-inventario/) — URH de R$ 216,22 e consulta de 1,5 URH. Fonte secundária: conferir no site da OAB-ES antes de usar em proposta.
- Estudo de implementação do projeto (`design/estudo-implementacao.html`) — semanas de trabalho por serviço e o tempo de revisão das traduções.
