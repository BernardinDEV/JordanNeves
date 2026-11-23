# Referência das rotas — v1

Referência · 23/11/2026. Parte da [documentação da API](README.md). Os objetos estão em
[`modelos.md`](modelos.md); os erros, em [`erros.md`](erros.md); a versão máquina, em
[`openapi.yaml`](openapi.yaml).

São as oito rotas que o app instalado já chama, em `AdvClient/Core/Services/Remote/BackendAPI.swift`.
O servidor precisa responder **exatamente** assim.

| Rota | Autenticação | Para quê | Resposta |
| --- | --- | --- | --- |
| [`POST /v1/auth/code`](#post-v1authcode) | não | Pede o código de acesso | `CodeChallenge` |
| [`POST /v1/auth/session`](#post-v1authsession) | não | Troca o código por sessão | `Session` |
| [`DELETE /v1/auth/session`](#delete-v1authsession) | sim | Encerra a sessão | vazio |
| [`GET /v1/snapshot`](#get-v1snapshot) | sim | Tudo o que o cliente vê | `Snapshot` |
| [`POST /v1/cases/{caseId}/hearing/confirmation`](#post-v1casescaseidhearingconfirmation) | sim | Confirma presença na audiência | `Snapshot` |
| [`POST /v1/pendencies/{pendencyId}/resolution`](#post-v1pendenciespendencyidresolution) | sim | Marca uma pendência como resolvida | `Snapshot` |
| [`POST /v1/documents`](#post-v1documents) | sim | Envia um arquivo ao escritório | `Snapshot` |
| [`POST /v1/events/whatsapp-handoff`](#post-v1eventswhatsapp-handoff) | sim | Registra a saída para o WhatsApp | vazio |

**Por que as ações devolvem o snapshot inteiro.** A tela nunca precisa adivinhar o que mudou:
confirmar uma audiência também resolve a pendência dela, muda o estado do caso e a contagem do
painel. O servidor aplica a regra uma vez e o app só desenha o resultado.

---

## `POST /v1/auth/code`

Pede um código de 6 dígitos para o e-mail. Detalhes e regras em
[`autenticacao.md`](autenticacao.md#pedir-o-código).

```http
POST /v1/auth/code HTTP/1.1
Host: jordanneves.api.exemplo.com.br
Content-Type: application/json; charset=utf-8
Accept-Language: pt-BR

{"email":"financeiro@costalog.com.br"}
```

```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: 01JD8Q4Z7M

{"expiresAt":"2026-11-23T15:10:00Z","resendAllowedAt":"2026-11-23T15:00:45Z"}
```

| Status | `code` | Quando |
| --- | --- | --- |
| 422 | `malformed_email` | Não é um e-mail |
| 404 | `unknown_email` | E-mail sem convite neste escritório |
| 429 | `too_many_requests` | Limite por e-mail ou por IP |

---

## `POST /v1/auth/session`

Troca o código por um token. Ver [`autenticacao.md`](autenticacao.md#abrir-a-sessão).

```json
{"email":"financeiro@costalog.com.br","code":"492718"}
```

```json
{
  "token": "Zx8...",
  "expiresAt": "2026-12-23T15:02:10Z",
  "company": {
    "id": "0b7c1d3e-8f40-4a5e-9a51-6c2d7f3e9a10",
    "legalName": "Costa Log Transportes Ltda",
    "tradeName": "Costa Log",
    "cnpj": "14.902.336/0001-08",
    "userEmail": "financeiro@costalog.com.br"
  }
}
```

| Status | `code` | Quando |
| --- | --- | --- |
| 422 | `invalid_code` | Código não confere |
| 422 | `code_expired` | Passou de `expiresAt`, já foi usado ou foi substituído por um reenvio |
| 404 | `unknown_email` | Convite removido entre o pedido e a confirmação |
| 429 | `too_many_attempts` | Quinta tentativa errada; o código morreu |

---

## `DELETE /v1/auth/session`

Revoga o token que veio no `Authorization`. Responde **`204`** sem corpo, inclusive se o token já
estava vencido ou revogado. O app apaga o token local de qualquer jeito.

---

## `GET /v1/snapshot`

Tudo o que o cliente vê, de uma vez: casos com andamentos publicados e audiência, documentos,
pendências, honorários e o que o escritório oferece. O objeto completo está em
[`modelos.md`](modelos.md#snapshot).

```http
GET /v1/snapshot HTTP/1.1
Authorization: Bearer Zx8...
Accept: application/json
Accept-Language: pt-BR
```

```json
{
  "syncedAt": "2026-11-23T11:30:00Z",
  "capabilities": { "documents": true, "uploads": true },
  "cases": [ { "id": "…", "number": "0012345-16.2025.5.17.0004", "…": "…" } ],
  "documents": [ … ],
  "pendencies": [ … ],
  "invoices": [ … ]
}
```

O que o servidor garante nesta resposta:

| Regra | Por quê |
| --- | --- |
| Só dados da empresa do token | Isolamento. O app não manda id de empresa e não filtra nada. |
| Só andamento **publicado** (tradução, aprovação e data de publicação) | Regra 1 do produto. O app confere de novo e esconde o que vier sem isso, mas o servidor não deve mandar. |
| Nunca andamento marcado `privado` no Projuris | Nem bruto, nem traduzido. |
| `officialText` de andamento publicado vai | O cliente pode abrir "texto oficial" debaixo da explicação. |
| Caso em segredo de justiça vai, com `underSeal: true` | O app mostra o aviso próprio no lugar da linha do tempo. |
| Documentos arquivados vão, com `archivedAt` | Nada é apagado pelo cliente; o histórico serve de prova. |
| Pendências resolvidas dos últimos 30 dias vão (proposto) | Para o cliente ver que o que fez chegou. |
| `syncedAt` é a hora da **última consulta bem-sucedida ao provedor** para esta empresa | O app mostra "Atualizado em …" literalmente. Nunca a hora da resposta. |

**Cache no aparelho.** O app guarda a resposta criptografada e, sem rede ou com o servidor fora,
mostra a guardada por até 7 dias dizendo desde quando. Com rede, sempre pede de novo (validade de
1 s, só para juntar telas que pedem ao mesmo tempo). O servidor pode — e deve — ter o próprio cache
por empresa, invalidado a cada publicação.

**Tamanho.** Sem paginação na v1. Com 100 casos e 20 andamentos publicados em cada, o corpo fica
na casa de 1 MB; use `gzip` (o app aceita). Se um escritório passar disso, a v2 pagina andamentos.

---

## `POST /v1/cases/{caseId}/hearing/confirmation`

O cliente confirma presença na próxima audiência do caso. Sem corpo.

```http
POST /v1/cases/11111111-1111-1111-1111-111111111111/hearing/confirmation HTTP/1.1
Authorization: Bearer Zx8...
```

**200** — o snapshot atualizado, em que:

- `cases[].hearing.confirmedAt` do caso ganha a hora da confirmação;
- toda pendência aberta do tipo `hearing` deste caso ganha `resolvedAt`;
- o estado do caso deixa de ser "Exige você", se nada mais pendia.

Do lado do escritório:

- a confirmação vai para o registro oficial — concluir a tarefa da audiência no Projuris ou
  registrar um andamento (decisão do escritório, em aberto);
- o responsável pelo caso é avisado no painel.

| Status | `code` | Quando |
| --- | --- | --- |
| 404 | `case_not_found` | Caso não existe ou é de outra empresa |
| 404 | `hearing_not_found` | Caso sem audiência marcada |
| 409 | `hearing_past` | A audiência já aconteceu |
| 409 | `hearing_changed` | A audiência foi remarcada desde o último snapshot (proposto) |

**Repetição.** Confirmar duas vezes devolve `200` com o mesmo snapshot e mantém a primeira hora de
confirmação. O app não repete `POST` sozinho, mas o cliente pode tocar em "Tentar de novo" depois de
uma resposta que se perdeu.

---

## `POST /v1/pendencies/{pendencyId}/resolution`

Marca uma pendência como resolvida pelo cliente. Sem corpo. **200** — o snapshot atualizado, com
`resolvedAt` preenchido.

Hoje nenhuma tela chama esta rota: pendências se resolvem pela ação que elas pedem (confirmar a
audiência, enviar o documento, decidir o contrato). Ela existe no contrato para o "já fiz" que o
escritório pediu, separando **lido** de **cumprido** ([`evolucao.md`](evolucao.md)).

| Status | `code` | Quando |
| --- | --- | --- |
| 404 | `pendency_not_found` | Não existe ou é de outra empresa |
| 409 | `pendency_not_resolvable` | O tipo só se resolve pela equipe (proposto) |

Repetir devolve `200` e mantém a primeira hora.

---

## `POST /v1/documents`

Envia um arquivo ao escritório. **Corpo cru**, sem multipart: um arquivo por chamada, metadados na
consulta.

```http
POST /v1/documents?caseId=11111111-1111-1111-1111-111111111111&fileName=procura%C3%A7%C3%A3o.pdf HTTP/1.1
Authorization: Bearer Zx8...
Content-Type: application/pdf
Content-Length: 482113

%PDF-1.7 …
```

| Parâmetro | Obrigatório | O quê |
| --- | --- | --- |
| `fileName` | sim | Nome do arquivo como o cliente o escolheu, com extensão. Pode ter acento e espaço (vem codificado). |
| `caseId` | não | Caso ao qual o arquivo se refere. Ausente: "nenhum caso específico". |
| `Content-Type` | sim | Tipo do arquivo pela extensão; `application/octet-stream` se o sistema não souber. |

**200** — o snapshot atualizado, com o documento novo em `documents`:

```json
{
  "id": "…novo…",
  "title": "procuração.pdf",
  "kind": "procedural",
  "caseId": "11111111-1111-1111-1111-111111111111",
  "autoRenews": false,
  "version": 1,
  "attentionPoints": [],
  "uploadedByClient": true,
  "uploadedAt": "2026-11-23T15:20:00Z"
}
```

`kind` é `procedural` com caso e `corporate` sem caso, como o app faz na demonstração. Depois da
resposta o app mostra "Arquivo enviado — o escritório foi avisado".

O que o servidor deve fazer:

| Regra | Valor |
| --- | --- |
| Tamanho máximo | 25 MB (o app já recusa acima disso). Responder `413` se passar. |
| Tipos aceitos (proposto) | PDF, JPEG, PNG, HEIC, DOC/DOCX, XLS/XLSX. Outros: `415`. |
| Conferir o conteúdo | Pelos primeiros bytes, não pelo `Content-Type` nem pela extensão |
| Antivírus | Antes de liberar o arquivo para a equipe |
| Guardar | No armazenamento de arquivos, criptografado, com escopo da empresa |
| Avisar | A equipe, no painel; o responsável pelo caso, se houver |
| Repassar ao Projuris | Em segundo plano, depois de responder ao app (`POST arquivo` multipart com `modulos_vinculo`) |
| Resposta | Logo depois de gravar. O app espera até 120 s. |

| Status | `code` | Quando |
| --- | --- | --- |
| 403 | `uploads_disabled` | O escritório desligou o envio (`capabilities.uploads: false`) |
| 404 | `case_not_found` | `caseId` não existe ou é de outra empresa |
| 413 | `file_too_large` | Acima de 25 MB |
| 415 | `unsupported_file_type` | Tipo não aceito |
| 422 | `missing_file_name` | Sem `fileName` ou corpo vazio |

**Repetição.** O app não reenvia sozinho. Se a resposta se perder e o cliente tocar em "Tentar de
novo", o mesmo arquivo chega duas vezes. Até existir a chave de idempotência
([`evolucao.md`](evolucao.md)), o servidor deve descartar envio igual (mesmo hash de conteúdo,
mesma empresa, mesmo caso) recebido em menos de 10 minutos e devolver o snapshot como está.

---

## `POST /v1/events/whatsapp-handoff`

Registra que o cliente tocou num botão de WhatsApp. Só o rastro: quem, qual caso, quando. O app
abre o WhatsApp sem esperar a resposta e ignora qualquer erro.

```json
{"caseId":"11111111-1111-1111-1111-111111111111"}
```

```json
{"caseId":null}
```

`caseId` vem `null` quando a conversa não é sobre um caso (contato geral, contrato, convite).
Responde **`204`**. Serve para o escritório medir quantos contatos o app gera e sobre o quê.

---

## Rotas planejadas

Não existem no app nem no servidor. Desenho em [`evolucao.md`](evolucao.md).

| Rota | Para quê |
| --- | --- |
| `POST /v1/auth/refresh` | Renovar a sessão sem novo código |
| `POST /v1/devices` | Registrar o token de notificação do aparelho |
| `DELETE /v1/devices/{token}` | Remover o registro ao sair |
| `POST /v1/cases/{caseId}/hearing/absence` | "Não poderei comparecer", com motivo |
| `GET /v1/documents/{id}/file` | Link assinado de curta duração para abrir o PDF |
| `PUT /v1/me/notification-preferences` | Preferências de notificação |
| `POST /v1/cases/{caseId}/questions` | Pergunta vinculada ao caso |
