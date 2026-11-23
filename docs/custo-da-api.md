# Custo de desenvolver a API do produto, e o que se reaproveita

Estimativa · 13/11/2026. Ordem de grandeza para decidir, não orçamento fechado.

## Resumo

Construir a API do produto (servidor, conector Projuris e painel da equipe) custa **10 a 14 semanas de trabalho, cerca de R$ 60 mil a R$ 84 mil** a R$ 150 por hora, e **R$ 300 a R$ 400 por mês** para manter no ar o primeiro escritório. Com reserva de 20% para imprevistos, planeje até R$ 100 mil.

Quase tudo isso é investimento único do produto, não do escritório: feito como um sistema para vários escritórios ao mesmo tempo (multi-inquilino), o segundo escritório que usa Projuris custa só a implantação, de uma a três semanas. Um provedor jurídico novo custa um conector, de duas a quatro semanas.

## O que precisa ser construído

| Módulo | O que entrega | Semanas |
| --- | --- | ---: |
| Fundação multi-inquilino | Banco com isolamento por escritório e por empresa cliente (regra no banco, não no app), login por código, sessões, arquivos, trilha de auditoria | 1,5 a 2 |
| API v1 | As 8 rotas que o app já chama, o snapshot montado a partir do banco, a regra de publicação, as capacidades por escritório | 1 a 1,5 |
| Conector Projuris | Token, varredura por `atualizadoDesde`, mapeamento, webhooks sem duplicar, testes contra a conta de homologação | 2,5 a 3,5 |
| Painel da equipe | Fila de tradução com rascunho por IA, cadastro de contratos e pontos de atenção, publicação de documentos, gestão de acessos | 3,5 a 5 |
| Tarefas agendadas e push | Alertas 60/30/7 dias, pendências, notificação só do que exige o cliente, no máximo uma por processo por dia | 1 |
| Segurança, LGPD e piloto | Revisão de acessos, retenção, exportação e exclusão, monitoramento, piloto com dois ou três clientes | 0,5 a 1 |
| **Total** | | **10 a 14** |

O painel da equipe é o maior bloco e o que não pode ser cortado: sem a fila de tradução, nada é publicado e o app fica vazio. As semanas partem do estudo de implementação do projeto, descontado o que o app já entrega.

## Quanto custa

**Desenvolvimento.** A R$ 150 por hora (desenvolvedor sênior como PJ, 40 horas por semana = R$ 6 mil por semana), 10 a 14 semanas dão **R$ 60 mil a R$ 84 mil**. Com a faixa de mercado de R$ 130 a R$ 200 por hora para sênior, o intervalo vai de R$ 52 mil a R$ 112 mil. Some 20% de reserva: integração com sistema de terceiro sempre traz surpresa.

**Operação, por mês, no primeiro escritório (50 empresas clientes):**

| Item | Custo por mês | Observação |
| --- | ---: | --- |
| Supabase Pro (banco, login, arquivos, tempo real) | cerca de R$ 140 | US$ 25 de plano; o crédito de US$ 10 cobre o menor servidor |
| Rascunhos de tradução com Claude Opus 5.5 | cerca de R$ 60 | ~300 andamentos por mês a uns R$ 0,21 cada |
| E-mail dos códigos de acesso | R$ 0 a 100 | Serviço de envio transacional |
| Monitoramento de erros | R$ 0 | Plano gratuito basta no início |
| Notificações (APNs) | R$ 0 | Sem custo da Apple |
| **Total** | **R$ 300 a 400** | Câmbio de R$ 5,50 por dólar, premissa |

A conta Apple Developer (US$ 99 por ano) e a API do Projuris ficam com o escritório. O custo de IA é desprezível: o caro na tradução é o minuto do advogado que revisa, não o modelo.

Como o rascunho foi estimado: uns 2 mil tokens de entrada (texto do tribunal, glossário do escritório, instruções) e 1,5 mil de saída por andamento, a US$ 4 e US$ 20 por milhão de tokens.

## Vantagens de ter a própria API

Em relação ao app falar direto com o Projuris, ou guardar tudo no CloudKit:

- **Segurança:** a credencial do Projuris, que abre a carteira inteira do escritório, nunca sai do servidor. Cada cliente só enxerga o que é dele, por regra do banco.
- **Independência do provedor:** trocar ou somar provedor (Projuris, Astrea, DataJud) é trocar um conector no servidor. O app não muda e não passa de novo pela revisão da Apple.
- **Uma regra num lugar só:** publicação só depois da tradução aprovada, o que é urgente e o limite de notificações valem igual para iPhone, Android e web.
- **O escritório no controle:** histórico, auditoria, prova, exportação e exclusão para a LGPD, painel do sócio. Nada fica na conta pessoal de alguém.
- **Android e web sem retrabalho:** são novos clientes da mesma API.
- **Base para o que vier:** conversa no app (tempo real do Supabase), relatórios, métricas de uso para cobrar por faixa.

## O que se reaproveita

O produto fica replicável se cada peça morar em uma de quatro camadas, e só a última mudar por escritório.

| Camada | O que é | Reaproveitamento |
| --- | --- | --- |
| App (já pronto) | White label (`Brand.json`, `nova-marca.py`, `verificar.py`), telas, contrato v1 implementado e testado, camada de rede com cache e segurança, dados de demonstração, manifesto de privacidade | Todo escritório, de qualquer provedor |
| Núcleo do servidor | Multi-inquilino, login, API v1, regras, painel da equipe, push, tarefas agendadas, auditoria, rascunho por IA | Todo escritório, de qualquer provedor |
| Conectores | Um por provedor jurídico, todos devolvendo o mesmo modelo | Todo escritório do mesmo provedor |
| Configuração do escritório | Linha do escritório no banco, credenciais no cofre, glossário de tradução, marca no `Brand.json`, conta Apple, chave de push | Só daquele escritório: dado, nunca código |

O que o app já entrega e encurta o servidor:

- **O contrato v1 já tem testes:** os exemplos de `ServiceLayerTests.swift` viram os casos de teste das respostas do servidor.
- **As regras já estão especificadas:** `Rules.swift` e `RulesTests.swift` descrevem publicação, urgência, escalonamento 60/30/7 e estado de cada caso. O servidor implementa as mesmas regras e roda os mesmos casos, para app e servidor nunca discordarem.
- **Os dados de demonstração** (empresa e pessoa física) servem de carga inicial do banco de homologação.

## Regras para continuar replicável

1. **Um sistema para todos os escritórios,** separado por escritório no banco, em vez de uma instalação por cliente. Escritório grande que exija isolamento ganha um projeto próprio com o mesmo código.
2. **Nada de código por escritório.** Diferença entre escritórios é configuração (capacidades, glossário, marca). Se precisou de um `if escritorio == …`, é configuração que falta.
3. **Contrato com versão.** O app fala com `/v1`. Mudança que quebra vira `/v2`, com as duas versões no ar até os apps atualizarem.
4. **Conector atrás de uma porta única,** com capacidades: o provedor que não tem documentos desliga a aba sozinho.
5. **Implantação por script.** Hoje `nova-marca.py` cria a marca no app; falta o par no servidor (criar o escritório, cadastrar credenciais, checar a conexão). É o que leva a implantação de três semanas para uma.

## Custo de crescer

| Passo | Custo | Quando se paga |
| --- | --- | --- |
| Primeiro escritório | R$ 60 mil a R$ 84 mil + 20% de reserva | Investimento do produto |
| Cada escritório novo com Projuris | 1 a 3 semanas de implantação | Coberto pela taxa de implantação (R$ 6 mil a R$ 12 mil) |
| Cada provedor jurídico novo | 2 a 4 semanas (R$ 12 mil a R$ 24 mil) | Quando houver escritórios suficientes nele |
| Operação por escritório a mais | Algumas dezenas de reais por mês | Dentro da mensalidade |

Com a mensalidade de R$ 990 sugerida em [valor-do-produto.md](valor-do-produto.md) e uns R$ 100 de operação por escritório, o desenvolvimento se paga com cerca de 80 meses-escritório: por exemplo, sete escritórios por um ano.

## Premissas

- Valor da hora de R$ 150, dentro da faixa de mercado de R$ 130 a R$ 260 para sênior como freelancer em 2026 ([Agilize](https://artigos.agilize.com.br/salario-dev-freelance-2026/), [Monitor do Mercado](https://monitordomercado.com.br/noticias/399275-quanto-um-programador-freelancer-cobra-por-hora-no-brasil-em-2026-e-o-que-define-o-nivel-junior-pleno-e-senior/)). Fábrica de software costuma cobrar mais; você desenvolvendo, o custo vira tempo.
- Supabase Pro a US$ 25 por mês com US$ 10 de crédito de servidor ([toolradar, conferido em 01/11/2026](https://toolradar.com/tools/supabase/pricing)). Conferir em supabase.com/pricing antes de contratar.
- Claude Opus 5.5 a US$ 4 por milhão de tokens de entrada e US$ 20 de saída (tabela de preços da Anthropic em novembro de 2026).
- Câmbio de R$ 5,50 por dólar.
- Semanas do estudo de implementação (`design/estudo-implementacao.html`), descontado o app pronto.
