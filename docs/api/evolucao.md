# Evolução do contrato

Desenho · 23/11/2026. Parte da [documentação da API](README.md). Tudo aqui é **proposto**: não está
no app nem no servidor. Cada item diz se exige versão nova do app.

## Política de versão

| Mudança | Pode na v1? | Como |
| --- | --- | --- |
| Campo novo em resposta | Sim | O app instalado ignora campo que não conhece |
| Rota nova | Sim | Apps antigos não a chamam |
| Campo opcional novo em requisição | Sim | |
| Valor novo de enumeração | **Só com app novo** | O app antigo não quebra, mas cai no valor padrão (área "Outros", pendência genérica). Mandar só a apps que conhecem o valor. |
| Campo obrigatório que passa a aceitar `null` | **Só com app novo** | O app antigo descarta o objeto. Mandar `null` só a apps que aceitam. |
| Renomear ou remover campo, mudar tipo ou sentido | Não | Vira `/v2`, com `/v1` no ar até os apps atualizarem |

Para saber o que cada app entende, o servidor lê a versão no `User-Agent`
(`{bundle id}/{versão} (iOS x.y)`).

### Versão mínima

Hoje não há como obrigar o cliente a atualizar. Proposta:

- O servidor guarda `versao_minima_app` por marca.
- Abaixo dela, toda rota responde `426` com `code: "app_version_unsupported"`.
- O app novo mostra "Atualize o app para continuar" com o link da loja (`store.appStoreID` do
  `Brand.json`). Exige app novo; o app de hoje mostra a frase genérica de erro.

Usar só para correção de segurança ou fim de `/v1`.

### Chave de idempotência

Hoje o servidor deduplica o envio de arquivo por hash ([`endpoints.md`](endpoints.md#post-v1documents)).
Proposta, exige app novo:

- Todo `POST` leva `Idempotency-Key: {uuid}`, gerado pelo app **por intenção do cliente** (o mesmo
  em "Tentar de novo").
- O servidor guarda chave + empresa + resposta por 24 horas e devolve a mesma resposta a uma
  repetição.

Com isso, o app pode passar a repetir `POST` sozinho em falha de rede.

## v1.1 — sessão e notificações

### `POST /v1/auth/refresh`

Renova a sessão sem novo código. Exige app novo.

```http
POST /v1/auth/refresh
Authorization: Bearer {token atual}
```

```json
{ "token": "…novo…", "expiresAt": "2027-01-22T15:00:00Z" }
```

- Só com token ainda válido. Vencido: `401` e o cliente volta ao login.
- O token antigo vale mais 60 segundos, para pedidos que já estavam no caminho.
- No app: renovar quando faltar menos de 7 dias, **uma renovação por vez** — vários pedidos
  recebendo `401` ao mesmo tempo não podem disparar várias renovações. A costura é
  `SessionTokenStore`.

### `POST /v1/devices`

Registra o aparelho para receber push. O app pede a permissão de notificação depois do primeiro
login, com o motivo na tela, e chama esta rota com o token que a Apple der.

```json
{
  "token": "a1b2c3…(hex da APNs)",
  "platform": "ios",
  "environment": "production",
  "appVersion": "2.0",
  "language": "pt-BR"
}
```

`204`. Chamar de novo com o mesmo token atualiza. `environment` é `sandbox` em build de
desenvolvimento.

### `DELETE /v1/devices/{token}`

Remove o registro. O app chama ao sair da conta, **antes** de `DELETE /v1/auth/session`. `204`
mesmo se não existir. Revogar a sessão no servidor também desativa os aparelhos dela.

### Corpo do push

```json
{
  "aps": {
    "alert": { "title": "Jordan Neves", "body": "Há algo para você no processo 0012345-16…" },
    "sound": "default",
    "thread-id": "case-11111111-1111-1111-1111-111111111111"
  },
  "route": "case",
  "caseId": "11111111-1111-1111-1111-111111111111"
}
```

`route` é `case`, `document` ou `notifications`, com o id correspondente. O app abre o destino ao
toque (`AppRoute`). Texto sempre no idioma de `language` e sem teor sigiloso.

### `PUT /v1/me/notification-preferences`

```json
{ "pendencies": true, "relevantUpdates": true, "weeklyDigest": true }
```

`pendencies` não pode ser desligado pelo cliente (é o que exige ação); o servidor ignora `false`
nele. Os valores atuais vêm num campo novo do snapshot, `me.notificationPreferences`.

## v1.1 — o que o escritório pediu

Do relatório de aprimoramentos do escritório
([`resposta-relatorio-jordan.md`](../resposta-relatorio-jordan.md)). Campos novos em objetos que já
existem são aditivos: o app de hoje ignora, o app novo mostra.

### Caso

```json
{
  "stage": "Aguardando a sentença",
  "waitingFor": "O juiz decidir sobre as provas. Costuma levar de 30 a 60 dias.",
  "lastCourtActivityAt": "2026-11-10T12:00:00Z",
  "lastCourtCheckAt": "2026-11-23T11:30:00Z",
  "lastTeamReviewAt": "2026-11-21T18:00:00Z",
  "officeActions": [
    {
      "id": "…",
      "kind": "filing",
      "status": "done",
      "title": "Contestação protocolada",
      "date": "2026-11-18T16:00:00Z",
      "responsible": "Dra. Ana Ribeiro"
    }
  ],
  "riskAssessment": {
    "level": "medium",
    "explanation": "Há prova documental a nosso favor; a testemunha da outra parte é o ponto fraco.",
    "assessedBy": "Dra. Ana Ribeiro",
    "assessedAt": "2026-10-02T12:00:00Z"
  }
}
```

| Campo | O quê | Quem preenche |
| --- | --- | --- |
| `stage` | Etapa concreta, no lugar de "Com o tribunal" / "Em dia" | Equipe, com modelos validados |
| `waitingFor` | O que se aguarda, para períodos sem novidade | Equipe |
| `lastCourtActivityAt` | Última movimentação no tribunal | Conector |
| `lastCourtCheckAt` | Última consulta bem-sucedida ao tribunal para este caso | Conector |
| `lastTeamReviewAt` | Última análise da equipe | Painel |
| `officeActions` | Providências do escritório na linha do tempo. `kind`: `analysis`, `draft`, `review`, `filing`, `meeting`, `other`. `status`: `planned`, `inProgress`, `done`. | Equipe |
| `riskAssessment` | Risco com quem avaliou, quando e por quê. Substitui `risk` no app novo. | Advogado responsável |

E `claimValue` passa a aceitar `null` ("valor não informado") — só para apps novos.

### Pendência

| Campo | O quê |
| --- | --- |
| `owner` | De quem é o prazo: `client`, `office`, `otherParty`. Hoje toda pendência é do cliente. |
| `readAt` | Quando o cliente viu. Separa **lido** de **cumprido** (`resolvedAt`). |

Rota: `POST /v1/pendencies/{id}/read` → snapshot.

### Documento enviado pelo cliente

| Campo | Valores |
| --- | --- |
| `reviewStatus` | `received`, `inReview`, `accepted`, `needsNewVersion` |
| `reviewNote` | Por que precisa de outra versão |

### Andamento

| Campo | O quê |
| --- | --- |
| `reviewedBy` | Quem revisou, com a especialidade |
| `publishedVersion` | Versão da explicação (a equipe pode corrigir depois de publicar) |

"Lido" sincronizado entre aparelhos: `POST /v1/movements/read` com `{ "ids": [...] }` → `204`; o
snapshot ganha `readMovementIds`.

### Audiência: "Não poderei comparecer"

`POST /v1/cases/{caseId}/hearing/absence`

```json
{ "reason": "Viagem a trabalho nesta data", "contactPreference": "whatsapp" }
```

Responde o snapshot, com uma pendência nova do lado do escritório e a audiência marcada como
`absenceReportedAt`. Hoje o botão abre o WhatsApp com a mensagem pronta; o registro não chega à
equipe pelo app.

### Abrir o documento

`GET /v1/documents/{id}/file` → `{ "url": "https://…assinada…", "expiresAt": "…" }`, válida por 5
minutos. O app abre com PDFKit. Hoje o app mostra uma prévia desenhada, não o PDF.

## v1.1 — perguntas no caso

O escritório pediu perguntas vinculadas ao caso, com resposta no app. Desenho inicial:

| Rota | Para quê |
| --- | --- |
| `GET /v1/cases/{caseId}/questions` | Perguntas e respostas do caso |
| `POST /v1/cases/{caseId}/questions` `{text, movementId?, documentId?}` | Nova pergunta, com o contexto |
| `POST /v1/questions/{id}/messages` `{text}` | Resposta ou complemento |

Do lado do escritório, uma caixa de entrada no painel com responsável e prazo; push quando a
resposta chega. Tempo real pelo banco (Supabase Realtime). O WhatsApp continua como alternativa.

## Depois

| Item | Estado |
| --- | --- |
| Abertura de novo processo pelo app | Jornada a definir com o escritório |
| Troca de empresa (uma pessoa, várias empresas) | Campo `companies` na sessão e `POST /v1/auth/session/company` |
| Papéis por pessoa (financeiro vê honorários, jurídico vê casos) | No servidor; o app esconde o que não vier |
| Paginação de andamentos | Só se um escritório passar de ~1 MB de snapshot |
| Android e web do cliente | Novos clientes da mesma API, sem mudança de contrato |
