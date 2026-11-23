# Rede e segurança

Referência · 23/11/2026. Parte da [documentação do app](README.md). Código em
`AdvClient/Core/Networking/` e `AdvClient/Core/Security/`; testes em
`AdvClientTests/NetworkingTests.swift`.

## A regra

**Nenhuma tela, repositório ou serviço monta `URLRequest` por conta própria.** Cache com escopo de
conta, bloqueio de ambiente comprometido, política de redirecionamento e log redigido valem para o
que passa pelo `APIClient`, e só. Uma chamada solta com `URLSession.shared` contorna as quatro de
uma vez.

## Peças

| Arquivo | O quê |
| --- | --- |
| `Endpoint.swift` | `Endpoint<Response>`: método, caminho, consulta, corpo, política de cache, tempo limite. Monta a `URLRequest`, recusa base sem HTTPS. Codificadores JSON do serviço. |
| `APIClient.swift` | Protocolo, `Fetched<Value>` (valor + origem + hora), transporte com nova tentativa, `LiveAPIClient` |
| `APIError.swift` | `APIProblem` (corpo de erro do servidor) e `APIError`, o único erro que a camada lança |
| `ResponseCache.swift` | Cache de duas camadas: memória e disco criptografado |
| `NetworkSecurity.swift` | Sessão endurecida, política de redirecionamento, `SecurityGate`, detecção de proxy |
| `NetworkLog.swift` | Log redigido na origem |

## Uma chamada, passo a passo

`LiveAPIClient.send(_:)`:

1. **Portaria do ambiente.** `SecurityGate` confirma que o aparelho não está comprometido. Se
   estiver: nada sai, o cache é apagado, a chamada falha com `insecureEnvironment`.
2. **Cache válido.** `GET` com política de cache e resposta guardada ainda dentro da validade:
   responde dali (`source = .cache`).
3. **Monta a requisição.** Cabeçalhos fixos, `Authorization` se a rota pede e o token não venceu.
4. **Rede**, com nova tentativa para método idempotente. `GET` iguais em andamento são juntados num
   só.
5. **Status.** Erro vira `APIError`. `401` apaga o token e **todo** o cache. Falha de
   infraestrutura com resposta guardada dentro da janela de reserva: responde com ela
   (`source = .staleCache`), marcada com a hora em que foi guardada.
6. **Decodifica e guarda.** `GET` cacheável vai para o cache.

## Erros

Um `APIError` para tudo; `URLError`, `DecodingError` e `NSError` passam por `APIError.mapping(_:)`
antes de subir. Cada caso responde, sem `switch` espalhado por tela:

| Propriedade | Pergunta |
| --- | --- |
| `userMessage` | Que frase o cliente lê? No idioma do app, sem status, sem inglês. |
| `isRetryable` | Cabe "Tentar de novo"? |
| `endsSession` | Derruba o login? Só `401`. |
| `allowsStaleFallback` | Vale mostrar o guardado? Só falha de infraestrutura — nunca `401` ou `403`. |
| `diagnostic` | O que vai para o log: status, `code`, `requestID`. Nunca o corpo. |

O texto do servidor (`detail`) nunca vai para a tela. A tabela completa de status e frases está em
[`../api/erros.md`](../api/erros.md).

Erros de login (`unknown_email`, `invalid_code`, `code_expired`, `malformed_email`) viram
`AuthError` em `RemoteAuthService`, com frase própria nas telas de acesso.

## Cache

| Política | Responde sem ir à rede | Ainda serve se a rede cair | Onde |
| --- | --- | --- | --- |
| `.oneHour` | 1 hora | 1 dia | memória + disco |
| `.oneDay` | 1 dia | 7 dias | memória + disco |
| `.oneHourInMemory` | 1 hora | — | só memória |
| snapshot (`custom`) | 1 segundo | 7 dias | memória + disco |
| `.none` (padrão) | — | — | — |

O snapshot quase não usa a primeira janela de propósito: o cache não vê os `POST`, e uma validade
longa faria "atualizar" depois de confirmar uma audiência mostrar o estado de antes. A segunda
janela existe porque o app mostra a data dos dados ao cliente: dado de ontem, dito que é de ontem, é
melhor do que tela vazia.

Proteções:

- **Só `GET` entra.**
- **`URLCache` do sistema desligado.** Ele grava o corpo em claro em `Library/Caches`, que entra em
  backup do aparelho.
- **Disco** em `Application Support`, com `NSFileProtectionComplete` (ilegível com o aparelho
  bloqueado) e fora do backup.
- **Chave** = `SHA-256(versão | conta | chamada)`. O nome do arquivo não diz de quem é, e trocar de
  conta no mesmo aparelho não lê o cache da outra.
- **Apagado** ao sair da conta, em qualquer `401` e quando o ambiente é dado como comprometido.

## Sessão HTTP

| Configuração | Por quê |
| --- | --- |
| Efêmera, sem cookie, sem credencial guardada | Nada do cliente fica no armazenamento do sistema |
| TLS 1.2 no mínimo | |
| ATS sem exceções, com transparência de certificado (`Info.plist`) | Certificado autoassinado não funciona nem em teste |
| `waitsForConnectivity = false` | Sem rede, falha rápido em vez de esperar em silêncio |
| `User-Agent` = `{bundle id}/{versão} (iOS x.y)` | Só o necessário; User-Agent detalhado vira impressão digital |
| Redirecionamento só HTTPS e mesmo host | O vazamento clássico de token é um `302` para outro domínio levando o `Authorization` junto |

## Nova tentativa

Até 3 tentativas, **só método idempotente** (`GET`, `PUT`, `DELETE`), só em `429`, `5xx` (menos
`501`), tempo esgotado e conexão perdida. Espera de 0,5 s e 1 s com ruído de até 0,25 s, ou o
`Retry-After` se for de até 5 s. `POST` nunca: reenviar um envio que talvez tenha chegado é como o
escritório recebe o mesmo documento duas vezes.

## Log

`os.Logger`, redigido na origem:

- sem parâmetros de consulta, sem corpo, sem cabeçalho;
- caminho com identificador mascarado: `/v1/cases/{id}/movements`;
- erro só com `diagnostic` (status, código, `requestID`).

Log de app iOS sai do controle do escritório no instante em que é escrito.

## Proteção de dados no aparelho

| Proteção | Como |
| --- | --- |
| Sessão e token | Keychain, `AfterFirstUnlockThisDeviceOnly`, sem sincronização com iCloud. Nunca `UserDefaults`. |
| Instalação nova | Apaga a sessão que o Keychain guardou de uma instalação anterior |
| Seletor de apps | Tela de privacidade cobre o conteúdo ao ir para o segundo plano ou ficar inativo |
| Face ID | Opcional; bloqueia ao voltar de um segundo plano de verdade (puxar a Central de Controle não bloqueia). Só destrava o aparelho — quem prova identidade ao servidor é o código por e-mail. |
| Aparelho comprometido | `TamperDetection` (jailbreak, depurador, biblioteca de interceptação) roda fora da thread principal ao abrir e ao voltar. Comprometido: tela de aviso, nenhuma requisição, cache apagado. O `SecurityGate` guarda o veredito por 5 minutos e revalida. |
| VoiceOver | Com qualquer tela de proteção por cima, o conteúdo embaixo fica oculto para o leitor de tela |
| Saída da conta | Avisa o servidor, apaga token, sessão e cache, solta o escopo da conta |

## O que falta

| Item | Peso | Depende de |
| --- | --- | --- |
| **Pinning de certificado** (hash SPKI do servidor e de uma chave reserva) | É o que mais pesa numa auditoria e o único que impede interceptação. Sem ele, um proxy com AC instalada no aparelho lê o tráfego; a detecção de proxy é sinal de log, não defesa. | Chaves do servidor. Entra em `RedirectPolicy`, que já é o delegado da sessão. |
| Renovação de sessão | Hoje o token vencido devolve o cliente ao login | `POST /v1/auth/refresh` ([`evolucao.md`](../api/evolucao.md)); uma renovação por vez em `SessionTokenStore` |
| Chave de idempotência em `POST` | Permite repetir `POST` sem duplicar | Servidor |
| Barra de progresso real no envio | Hoje é indicativa | `URLSession.upload(for:from:delegate:)` |
