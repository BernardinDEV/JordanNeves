# Erros

Referência · 23/11/2026. Parte da [documentação da API](README.md). No app:
`AdvClient/Core/Networking/APIError.swift`.

## Corpo de erro

Toda resposta de erro leva um corpo JSON assim, com `Content-Type: application/json`:

```json
{
  "code": "hearing_past",
  "detail": "Hearing 3333… happened on 2026-11-14; confirmation refused.",
  "requestId": "01JD8Q4Z7M",
  "fields": { "email": "formato inválido" }
}
```

| Campo | Obrig. | Para quê |
| --- | --- | --- |
| `code` | sim | Identificador estável, `snake_case`, em inglês. **É o único campo em que o app ramifica.** Uma vez publicado, não muda de sentido. |
| `detail` | não | Texto para o log do servidor e do suporte. **Nunca aparece ao cliente.** Pode estar em inglês e citar ids. |
| `requestId` | sim | O mesmo do cabeçalho `X-Request-ID` |
| `fields` | não | Erros por campo em validação de formulário. Mapa de texto, ou de lista de textos. |

O app também lê o formato do RFC 9457 (`type`, `title`, `detail`) e o informal
(`error`, `message`, `errors`, `request_id`), para não quebrar se o framework do servidor mudar. O
formato acima é o padrão do produto.

### Por que o `detail` não vai para a tela

Pode vir em inglês, pode citar nome de tabela, pode citar o CNPJ de outro cliente num bug. O
cliente lê sempre uma frase escrita pelo app, no idioma escolhido no app, sem status e sem código.

## Status e o que o app faz

| Status | Caso no app | Frase ao cliente (pt-BR) | Repete sozinho¹ | Derruba a sessão | Mostra o guardado² |
| --- | --- | --- | --- | --- | --- |
| 400, 422 | `invalidData` | "Não foi possível concluir com os dados enviados. Confira e tente de novo." | não | não | não |
| 401 | `unauthorized` | "Sua sessão expirou. Entre novamente para continuar." | não | **sim** | **não** |
| 403 | `forbidden` | "Este conteúdo não está liberado para o seu acesso. Fale com o escritório." | não | não | **não** |
| 404, 410 | `notFound` | "Não encontramos este item. Ele pode ter sido movido ou arquivado." | não | não | não |
| 409, 412 | `conflict` | "Este item mudou enquanto você estava nesta tela. Atualize e tente de novo." | não | não | não |
| 429 | `rateLimited` | "Muitas tentativas seguidas. Aguarde um instante e tente de novo." | sim | não | sim |
| 500–599 (menos 501) | `server` | "O serviço está indisponível agora. Tente de novo em alguns minutos." | sim | não | sim |
| 501 | `server` | idem | não | não | sim |
| 3xx | `insecureTransport` | frase de conexão insegura | não | não | não |
| outro | `unexpectedStatus` | "Não foi possível carregar agora. Tente de novo." | não | não | não |
| sem rede | `offline` | "Sem conexão. O que aparece aqui é o que guardamos da última vez." | não | não | sim |
| tempo esgotado | `timedOut` | frase de tempo esgotado | sim | não | sim |
| JSON fora do contrato | `malformedResponse` | frase genérica | não | não | não |

¹ Só `GET`, `PUT` e `DELETE`, até 3 tentativas. `POST` nunca. Ver
[nova tentativa](README.md#nova-tentativa).
² Só `GET /v1/snapshot` tem o que mostrar, por até 7 dias, com a data.

Detalhes que mordem:

- **`401` é o único que derruba a sessão**, e derruba em qualquer rota: o app apaga o token e o
  cache do aparelho e volta ao login. Não use `401` para "sem permissão neste caso" — isso é `403`
  ou `404`.
- **`403` e `401` nunca caem no guardado.** Mostrar dado do cache a quem o servidor acabou de
  recusar é o vazamento que o cache não pode causar.
- **`413` e `415`** caem em `unexpectedStatus`, com a frase genérica. O app já barra acima de 25 MB
  antes de enviar; o `415` aparece só se o servidor recusar um tipo.
- **`Retry-After`** em segundos inteiros. Acima de 5 s o app não espera: mostra o erro.

## Códigos estáveis

Os que o app instalado **reconhece** e transforma em frase própria:

| `code` | Status | Rota | Frase |
| --- | --- | --- | --- |
| `malformed_email` | 422 | `auth/code`, `auth/session` | "Confira o endereço de e-mail." |
| `unknown_email` | 404 | `auth/code`, `auth/session` | "Este e-mail não está na lista de acessos do escritório." |
| `invalid_code` | 422 | `auth/session` | "Código incorreto. Tente novamente." |
| `code_expired` | 422 | `auth/session` | "O código expirou. Peça um novo." |

Os demais o app ainda trata pelo status. O servidor os manda desde já, para o log e para versões
futuras do app:

| `code` | Status | Quando |
| --- | --- | --- |
| `too_many_requests` | 429 | Limite de pedidos de código |
| `too_many_attempts` | 429 | Quinta tentativa errada de código |
| `session_expired` | 401 | Token vencido |
| `session_revoked` | 401 | Token revogado (saída, acesso removido) |
| `case_not_found` | 404 | Caso inexistente ou de outra empresa |
| `hearing_not_found` | 404 | Caso sem audiência |
| `hearing_past` | 409 | Audiência já aconteceu |
| `hearing_changed` | 409 | Audiência remarcada desde o último snapshot |
| `pendency_not_found` | 404 | Pendência inexistente ou de outra empresa |
| `pendency_not_resolvable` | 409 | Só a equipe resolve este tipo |
| `uploads_disabled` | 403 | Envio desligado para o escritório |
| `file_too_large` | 413 | Acima de 25 MB |
| `unsupported_file_type` | 415 | Tipo não aceito |
| `missing_file_name` | 422 | Envio sem nome ou sem corpo |
| `app_version_unsupported` | 426 | Versão do app abaixo do mínimo (proposto, ver [`evolucao.md`](evolucao.md)) |
| `provider_unavailable` | 503 | O provedor jurídico está fora; dados do banco ainda servem |
| `internal_error` | 500 | Qualquer outro |

Recurso de outra empresa responde **`404`**, igual ao inexistente. `403` confirmaria que ele existe.

## Log e suporte

O que o app grava no log do aparelho (`os.Logger`) quando uma chamada falha:

```
✕ /v1/cases/{id}/hearing/confirmation — conflito status=409 code=hearing_past req=01JD8Q4Z7M
```

Sem corpo, sem cabeçalho, sem `detail`, sem parâmetro de consulta, com o id do caminho mascarado.
O `requestId` é a ponte para o log do servidor — por isso ele é obrigatório em todo erro.

O servidor também não registra corpo de resposta, token, código de acesso nem `detail` com dado do
cliente. Ver [`servidor.md`](servidor.md#observabilidade).
