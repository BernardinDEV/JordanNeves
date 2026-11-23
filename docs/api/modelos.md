# Modelos de dados — v1

Referência · 23/11/2026. Parte da [documentação da API](README.md). Fonte de verdade no app:
`AdvClient/Core/Services/Remote/DTO/` (fio) e `SnapshotDTO+Domain.swift` (o que o app faz com cada
valor).

## Como ler as tabelas

- **Obrigatório: sim** — o campo tem que vir, com o tipo certo. Se faltar, o app descarta o
  **objeto inteiro** que o contém (ver a coluna "Se faltar ou vier errado" de cada objeto).
- **Obrigatório: não** — pode vir ausente ou `null`.
- Tipos: `uuid` e `data` são texto (ver [convenções](README.md#corpo)); `dinheiro` é texto decimal
  com ponto (`"84200.50"`).

### O que se perde quando algo vem errado

As listas do snapshot são tolerantes: um item malformado é descartado e os outros seguem. Mas o
descarte acontece **no nível da lista mais próxima**, e isso define o tamanho do estrago:

| Erro em… | O app descarta | O cliente percebe |
| --- | --- | --- |
| `syncedAt` ou uma das quatro listas ausente | o snapshot inteiro | Falha de carga; mostra o guardado com a data |
| Um campo obrigatório de um caso | o caso | **O processo some sem aviso** |
| A audiência de um caso, ou um item do checklist dela | **o caso inteiro** | O processo some sem aviso |
| Um andamento | só o andamento | Linha do tempo com um item a menos |
| Um documento, ou um ponto de atenção dele | o documento | O documento some |
| Uma pendência | a pendência | — |
| Um honorário | o honorário | — |

Caso que some sem aviso é o pior defeito possível neste produto. **O servidor deve validar o
snapshot contra este documento antes de responder**, em teste automatizado e, em produção, com
alerta quando um objeto não passar.

---

## Snapshot

Resposta de `GET /v1/snapshot` e das três ações.

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `syncedAt` | data | sim | Última consulta bem-sucedida ao provedor jurídico para esta empresa. Aparece ao cliente como "Atualizado em …". |
| `cases` | [Case] | sim | Todos os casos da empresa, abertos e encerrados. Lista vazia vale. |
| `documents` | [Document] | sim | Contratos, peças e documentos societários ou pessoais |
| `pendencies` | [Pendency] | sim | O que exige o cliente, abertas e resolvidas recentes |
| `invoices` | [Invoice] | sim | Honorários |
| `capabilities` | Capabilities | não | O que o escritório oferece. Ausente: tudo ligado. |

## Capabilities

| Campo | Tipo | Obrig. | O app |
| --- | --- | --- | --- |
| `documents` | bool | sim | `false` esconde a aba Documentos, os contratos do painel e o "Ver todos" |
| `uploads` | bool | sim | `false` esconde o botão de envio. Só vale com `documents: true`. |

Vem no snapshot, e não na sessão, para valer também quando o app mostra o snapshot guardado, sem
rede. Escritório sem documentos no provedor e sem cadastro no painel deve mandar
`documents: false` em vez de uma aba vazia.

## Case

Um processo.

| Campo | Tipo | Obrig. | O quê | O app |
| --- | --- | --- | --- | --- |
| `id` | uuid | sim | Id nosso, estável | Rotas, "lido", navegação |
| `number` | texto | sim | Número CNJ, com ou sem máscara (`0012345-16.2025.5.17.0004`) | Mostra com máscara; vai na mensagem do WhatsApp |
| `title` | texto | sim | Título em português claro ("Reclamação trabalhista — ex-motorista") | Título do cartão |
| `area` | enum | sim | Área do direito, ver [enumerações](#enumerações) | Ícone e rótulo; desconhecida vira "Outros" |
| `court` | texto | sim | Vara por extenso ("4ª Vara do Trabalho de Vitória") | Linha "Vara"; vazio esconde |
| `courtShort` | texto | sim | Sigla do tribunal ("TRT-17") | Selo do cartão |
| `underSeal` | bool | sim | Segredo de justiça | Aviso próprio no lugar da linha do tempo |
| `opposingParty` | texto | sim | Parte contrária. **`""` quando não se sabe.** | Vazio esconde a linha |
| `claimValue` | dinheiro | sim | Valor da causa | Texto que não é número: **o caso é descartado** |
| `risk` | enum | não | `low`, `medium`, `high` | Ausente ou desconhecido esconde a linha de risco |
| `provision` | dinheiro | não | Provisão contábil estimada | A linha de risco só aparece com provisão **e** risco conhecido |
| `responsibleLawyer` | texto | sim | Nome do advogado responsável. `""` quando não há. | Vazio esconde a linha "Responsável" |
| `openedAt` | data | sim | Abertura | Ordenação; base do "sem novidade" |
| `closedAt` | data | não | Encerramento | Presente: caso vai para "Encerrados" |
| `movements` | [Movement] | sim | **Só os publicados.** Lista vazia vale. | Linha do tempo |
| `hearing` | Hearing | não | Próxima audiência | Cartão "Seu próximo passo" e a folha da audiência |

Limitação conhecida da v1: o app instalado exige `claimValue` numérico e não tem como dizer "valor
não informado". O servidor deve mandar o valor do Projuris; se não houver, `"0.00"` aparece como
R$ 0,00. A v1.1 aceita `null` ([`evolucao.md`](evolucao.md)) — e o servidor só pode mandar `null`
a apps que já entendem, senão o caso some.

## Movement

Um andamento **publicado**: texto do tribunal mais a explicação aprovada pelo escritório.

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `id` | uuid | sim | Id nosso |
| `date` | data | sim | Data do andamento no tribunal (não da publicação no app) |
| `officialText` | texto | sim | Texto do tribunal como veio, para "ver texto oficial" |
| `headline` | texto | não | Uma linha em português claro, o título na linha do tempo ("O juiz aceitou o adiamento") |
| `translation` | texto | **na prática, sim** | A explicação do que isso significa para a empresa |
| `requiresClient` | bool | sim | O cliente precisa fazer algo? |
| `approvedBy` | texto | **na prática, sim** | Nome de quem aprovou a tradução |
| `approvedAt` | data | não | Quando aprovou |
| `publishedAt` | data | **na prática, sim** | Quando ficou visível ao cliente |

"Na prática, sim": o tipo aceita ausência, mas o app **esconde** o andamento que vier sem
`translation` não vazia, sem `approvedBy` não vazio ou sem `publishedAt` (`Rules.isPublished`). O
servidor não deve mandar andamento não publicado; se mandar, ele não aparece.

Sem `headline`, o app usa a `translation` como título.

## Hearing

A próxima audiência de um caso. Uma por caso na v1.

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `id` | uuid | sim | |
| `date` | data | sim | Data e hora, com fuso. Mostrada no fuso do escritório. |
| `venue` | texto | sim | Local ("Fórum Trabalhista de Vitória, sala 4") |
| `address` | texto | sim | Endereço, vai para o calendário (`.ics`) |
| `whoMustAttend` | texto | sim | Em palavras simples ("Um preposto da empresa e a testemunha") |
| `checklist` | [ChecklistItem] | sim | "Leve com você". Lista vazia vale. |
| `confirmedAt` | data | não | Presente: presença confirmada |

Erro em qualquer campo aqui descarta **o caso inteiro**. Na dúvida sobre um campo de texto, mande
`""`, nunca omita.

Audiência já passada não deve vir em `hearing`: ela vira andamento.

### ChecklistItem

| Campo | Tipo | Obrig. |
| --- | --- | --- |
| `id` | uuid | sim |
| `text` | texto | sim |
| `checked` | bool | sim |

## Document

Um documento: contrato que o escritório acompanha, peça de processo, documento societário (ou
pessoal, em conta de pessoa física), ou arquivo que o cliente enviou.

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `id` | uuid | sim | |
| `title` | texto | sim | Nome que o cliente reconhece ("Contrato de transporte — Suzano") |
| `kind` | enum | sim | `contract`, `procedural`, `corporate`. Desconhecido: `procedural` se tiver `caseId`, senão `corporate`. |
| `caseId` | uuid | não | Caso a que pertence |
| `counterparty` | texto | não | A outra parte do contrato |
| `effectiveFrom` | data | não | Início da vigência |
| `expiresAt` | data | não | Fim da vigência |
| `noticeDeadline` | data | não | **Prazo para avisar que não renova.** Obrigatório na prática quando `autoRenews` é `true`. |
| `autoRenews` | bool | sim | Renova sozinho |
| `monthlyValue` | dinheiro | não | Valor mensal. Presente e ilegível: o documento é descartado. |
| `version` | inteiro | sim | Versão do arquivo, começa em 1 |
| `attentionPoints` | [AttentionPoint] | sim | Cláusulas que o escritório marcou. Lista vazia vale. |
| `uploadedByClient` | bool | sim | O cliente que enviou |
| `uploadedAt` | data | sim | Quando entrou |
| `archivedAt` | data | não | Arquivado: sai dos alertas, continua na lista |

**A data que move os alertas** é `noticeDeadline` quando existe, senão `expiresAt`. É sobre ela
que corre o escalonamento 60/30/7 ([regras](../regras-do-produto.md#3-contratos-escalonamento-60307)).
Contrato que renova sozinho sem `noticeDeadline` alerta sobre o vencimento, que é tarde demais —
o painel da equipe deve exigir o campo.

### AttentionPoint

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `id` | uuid | sim | |
| `clause` | texto | sim | "Cláusula 12.3" |
| `title` | texto | sim | "Multa de rescisão" |
| `detail` | texto | sim | A explicação |
| `warning` | bool | sim | `true` pinta como alerta |

## Pendency

Algo que exige o cliente. É a fonte única do "Exige você" no painel, nas notificações e nos
documentos.

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `id` | uuid | sim | |
| `kind` | enum | sim | `hearing`, `contractDecision`, `documentRequest` |
| `title` | texto | sim | A ação exata ("Enviar a procuração assinada") |
| `detail` | texto | sim | Contexto; `""` vale |
| `dueDate` | data | sim | Até quando |
| `caseId` | uuid | não | Caso a que se refere |
| `documentId` | uuid | não | Documento a que se refere |
| `resolvedAt` | data | não | Presente: resolvida |

Pendência **nunca** é descartada por tipo desconhecido: vira `documentRequest`, que continua
exigindo o cliente e leva ao documento ou ao caso. Para onde o toque leva:

| `kind` | Leva a |
| --- | --- |
| `hearing` | o caso (`caseId` obrigatório na prática; sem ele a linha não é tocável) |
| `contractDecision`, `documentRequest` | o documento, se houver `documentId`; senão o caso; senão nada |

## Invoice

Honorários. O Perfil mostra a próxima fatura em aberto.

| Campo | Tipo | Obrig. | O quê |
| --- | --- | --- | --- |
| `id` | uuid | sim | |
| `reference` | texto | sim | "11/2026" |
| `amount` | dinheiro | sim | Ilegível: o honorário é descartado |
| `dueDate` | data | sim | Vencimento |
| `paidAt` | data | não | Presente: paga |

## Company

Vem só na resposta de `POST /v1/auth/session`. Ver
[`autenticacao.md`](autenticacao.md#abrir-a-sessão).

| Campo | Tipo | Obrig. |
| --- | --- | --- |
| `id` | uuid | sim |
| `legalName` | texto | sim |
| `tradeName` | texto | sim |
| `cnpj` | texto | sim — CNPJ ou CPF; 11 dígitos = pessoa física |
| `userEmail` | texto | sim |

## Enumerações

Os valores são exatamente estes, em `camelCase`. Valor novo não quebra o app instalado, mas cai no
tratamento da última coluna — então valor novo só entra junto com uma versão do app que o conheça.

| Campo | Valores | Valor desconhecido |
| --- | --- | --- |
| `Case.area` | `labor`, `tax`, `civil`, `corporate`, `contracts`, `family` | "Outros" |
| `Case.risk` | `low`, `medium`, `high` | Linha de risco escondida |
| `Document.kind` | `contract`, `procedural`, `corporate` | `procedural` com caso, `corporate` sem |
| `Pendency.kind` | `hearing`, `contractDecision`, `documentRequest` | `documentRequest` |

## Exemplo completo

```json
{
  "syncedAt": "2026-11-23T11:30:00Z",
  "capabilities": { "documents": true, "uploads": true },
  "cases": [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "number": "0012345-16.2025.5.17.0004",
      "title": "Reclamação trabalhista — ex-motorista",
      "area": "labor",
      "court": "4ª Vara do Trabalho de Vitória",
      "courtShort": "TRT-17",
      "underSeal": false,
      "opposingParty": "J. R. da Silva",
      "claimValue": "84200.50",
      "risk": "medium",
      "provision": "32000.00",
      "responsibleLawyer": "Dra. Ana Ribeiro",
      "openedAt": "2025-01-10T12:00:00Z",
      "closedAt": null,
      "movements": [
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "date": "2026-10-30T12:00:00Z",
          "officialText": "Defiro o pedido de adiamento formulado pela reclamada.",
          "headline": "O juiz aceitou o adiamento",
          "translation": "A audiência que seria em 5/11 foi remarcada a nosso pedido. Nada muda no caso.",
          "requiresClient": false,
          "approvedBy": "Dra. Ana Ribeiro",
          "approvedAt": "2026-10-30T13:00:00Z",
          "publishedAt": "2026-10-30T13:05:00Z"
        }
      ],
      "hearing": {
        "id": "33333333-3333-3333-3333-333333333333",
        "date": "2026-12-04T17:30:00Z",
        "venue": "Fórum Trabalhista de Vitória, sala 4",
        "address": "Av. Champagnat, 200 — Vitória/ES",
        "whoMustAttend": "Um preposto da empresa com carta de preposição",
        "checklist": [
          { "id": "44444444-4444-4444-4444-444444444444", "text": "Carta de preposição assinada", "checked": false },
          { "id": "44444444-4444-4444-4444-444444444445", "text": "Documento com foto", "checked": false }
        ],
        "confirmedAt": null
      }
    }
  ],
  "documents": [
    {
      "id": "77777777-7777-7777-7777-777777777777",
      "title": "Contrato de transporte — Suzano",
      "kind": "contract",
      "caseId": null,
      "counterparty": "Suzano S.A.",
      "effectiveFrom": "2025-01-13T12:00:00Z",
      "expiresAt": "2027-01-13T12:00:00Z",
      "noticeDeadline": "2026-12-14T12:00:00Z",
      "autoRenews": true,
      "monthlyValue": "214900.00",
      "version": 2,
      "attentionPoints": [
        {
          "id": "aaaaaaaa-0000-0000-0000-000000000001",
          "clause": "Cláusula 12.3",
          "title": "Aviso de 30 dias para não renovar",
          "detail": "Sem o aviso até 14/12, o contrato renova por mais 24 meses no mesmo valor.",
          "warning": true
        }
      ],
      "uploadedByClient": false,
      "uploadedAt": "2026-01-13T12:00:00Z",
      "archivedAt": null
    }
  ],
  "pendencies": [
    {
      "id": "88888888-8888-8888-8888-888888888888",
      "kind": "hearing",
      "title": "Confirmar presença na audiência",
      "detail": "Precisamos saber quem vai como preposto.",
      "dueDate": "2026-11-28T21:00:00Z",
      "caseId": "11111111-1111-1111-1111-111111111111",
      "documentId": null,
      "resolvedAt": null
    }
  ],
  "invoices": [
    {
      "id": "99999999-9999-9999-9999-999999999999",
      "reference": "11/2026",
      "amount": "9800.00",
      "dueDate": "2026-11-30T12:00:00Z",
      "paidAt": null
    }
  ]
}
```
