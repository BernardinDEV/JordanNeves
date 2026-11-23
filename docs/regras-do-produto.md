# Regras do produto

Referência · 23/11/2026. Valem para o app e para o servidor. No app estão em
`AdvClient/Core/Rules.swift`, como funções puras sobre um `now` recebido, com os casos de teste em
`AdvClientTests/RulesTests.swift`. **O servidor implementa as mesmas regras e roda os mesmos
casos**, para que o painel, as notificações e o app nunca discordem sobre o que é urgente.

Ligado a: [API](api/README.md) · [app](app/README.md).

## Calendário

Toda conta de dias é em **dias inteiros no fuso `America/Sao_Paulo`**, não em horas. "Amanhã às 9h"
visto "hoje às 23h" está a 1 dia, não a 0. Datas e horas também aparecem ao cliente nesse fuso,
qualquer que seja o fuso do aparelho.

`dias(de, até)` = dias entre o início do dia de cada data. Negativo quando já passou.

## 1. Publicação

> Nenhum andamento chega ao cliente sem tradução em português claro **e** aprovação humana
> registrada.

Um andamento está publicado quando tem, ao mesmo tempo:

- `translation` não vazia (depois de tirar espaços);
- `approvedBy` não vazio;
- `publishedAt` preenchido.

| Onde | O que faz |
| --- | --- |
| Servidor | Só manda andamento publicado no snapshot. Andamento `privado` no provedor nunca é publicado. |
| Painel | Publicar exige tradução, "exige o cliente?" decidido e aprovação de alguém da equipe |
| App | Confere de novo (`Rules.isPublished`) e esconde o que não passar. Nenhuma tela contorna. |

É o que separa o produto de um portal de consulta processual, e é trabalho diário da equipe: sem a
fila de tradução andando, o app fica sem novidades.

O texto do tribunal (`officialText`) só aparece depois de publicado, debaixo da explicação, em "ver
texto oficial". Na fonte somente leitura de teste, que não tem explicação, o app mostra só a data e
a origem da última movimentação.

## 2. "Exige você" e "Para saber"

Todo andamento publicado cai em um dos dois grupos, pelo campo `requiresClient`, que a equipe
decide ao aprovar.

| | Exige você | Para saber |
| --- | --- | --- |
| Painel | Seção "Exige você", no topo | Não aparece; o caso fica "Em dia" |
| Notificações no app | Seção "Exige você" (as pendências abertas) | Seção "Para saber" (os 8 mais recentes); os dos últimos 14 dias contam como não lidos |
| Push | Sim, com teto | Não; entra no resumo semanal |

O mesmo corte vale no painel, nas notificações, nos documentos e nos casos.

## 3. Contratos: escalonamento 60/30/7

A data que importa é o **prazo de aviso prévio** (`noticeDeadline`) quando o contrato renova
sozinho, e o vencimento (`expiresAt`) quando não renova. O prazo de aviso vem sempre antes — é a
data que força a decisão.

| Dias até a data | Alerta | No app | Push |
| --- | --- | --- | --- |
| mais de 60 | nenhum | — | — |
| 31 a 60 | `watch` | Selo âmbar discreto na lista | não |
| 8 a 30 | `decide` | Sobe para "Precisa de você" em Documentos | não |
| 7 ou menos, **inclusive já vencido** | `urgent` | Idem, em vermelho | **sim** |

Contrato arquivado ou sem data não alerta. Contrato vencido continua `urgent`: a decisão ficou mais
urgente, não menos, e tirar o alerta é como um contrato vencido passa despercebido.

## 4. Prazo é data + contagem

Todo prazo aparece como data e contagem juntas, em fonte mono tabular:

```
14/09/2026 · em 54 dias
```

Nunca só "em 54 dias" (o cliente precisa da data para a agenda) nem só a data (ele precisa da
contagem para sentir a urgência).

### Urgência de um prazo

| Dias até a data | Urgência | Cor |
| --- | --- | --- |
| 0 ou menos (hoje ou passado) | `critical` | vermelho |
| 1 a 7 | `warning` | âmbar |
| 8 ou mais | `normal` | neutro |

Cor nunca sozinha: toda urgência leva palavra junto. Verde, âmbar e vermelho são fixos no código e
**não** mudam por escritório — verde significa "sem pendência" em qualquer marca.

## 5. Segredo de justiça

Caso com `underSeal: true` tem estado próprio: nenhuma fonte automática publica as movimentações, e
o app diz isso no lugar da linha do tempo, com o caminho para falar com o responsável. Nunca parece
parado sem explicação.

## Estado de um caso

Derivado, nunca guardado. A ordem importa: a primeira regra que vale decide.

| # | Condição | Estado | Rótulo |
| --- | --- | --- | --- |
| 1 | Há pendência aberta deste caso | `requiresYou` | Exige você |
| 2 | Há audiência não confirmada a 7 dias ou menos | `requiresYou` | Exige você |
| 3 | O andamento publicado mais recente exige o cliente **e** tem 30 dias ou menos | `deadlineNear` | Prazo próximo |
| 4 | A última atividade (andamento publicado ou, sem ele, movimentação no tribunal) tem mais de 30 dias | `withCourt` | Com o tribunal |
| 5 | Nenhuma das anteriores | `onTrack` | Em dia |

### Posição jurídica (barra do painel)

Só casos **abertos**. Três segmentos: Exige você, Prazo próximo, Em dia (este soma "com o tribunal"
e "em dia"). Encerrados ficam de fora porque inflariam o "em dia".

### Ordem

- **"Exige você" no painel:** casos abertos em `requiresYou`, pelo prazo mais próximo — a menor data
  entre as pendências abertas do caso e a audiência não confirmada.
- **Pendências:** abertas, pelo vencimento.
- **Documentos que precisam de você:** `decide` e `urgent`, pela data que move o alerta.

## Notificações (push)

Responsabilidade do servidor. O app só recebe.

| Regra | Valor |
| --- | --- |
| O que gera push | Andamento publicado com `requiresClient`; pendência nova; contrato chegando a `urgent`; audiência não confirmada ao entrar na janela de 7 dias |
| Lembretes de audiência confirmada | Na véspera e 1 hora antes — é o que a tela de confirmação promete ao cliente. Não contam no teto. |
| Teto | **Um push por caso por dia** (dia no fuso de São Paulo). Vários no mesmo dia: vai o mais recente. |
| O resto | Resumo semanal, sem push |
| Texto | Sem conteúdo sigiloso: diz que há algo e em qual caso, nunca o teor. Aparece na tela bloqueada. |
| Quem decide | O servidor. O teto não é preferência do usuário: se alguém precisa desligar as notificações para parar de ser incomodado, o produto já falhou. |

No app, `Rules.throttledPushes` implementa o teto para os testes; o servidor é quem aplica.

## "Lido"

Hoje o app guarda em memória quais andamentos o cliente abriu, só para o selo de não lidos
assentar; ao fechar o app, volta tudo. O contador soma as pendências abertas e os andamentos "para
saber" dos últimos 14 dias ainda não abertos. Sincronizar "lido" com o servidor está em
[`api/evolucao.md`](api/evolucao.md).

## Casos de teste

`AdvClientTests/RulesTests.swift` tem os casos que fixam cada regra acima — inclusive os de borda:
dias de calendário em vez de 24 horas, contrato vencido, renovação automática pelo aviso prévio,
andamento antigo que exigia o cliente, caso encerrado fora do "exige você", carteira vazia. São 39
testes. O servidor deve portar esse arquivo como está, com os mesmos `now` fixos.
