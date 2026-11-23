# Camada de serviço — desenho

Estado em 10/11/2026: **o lado do app está implementado e testado** contra um cliente falso; o
backend e o conector do Projuris **não existem ainda**. As duas marcas seguem em `"mode": "demo"`.
Baseado na documentação técnica da API do Projuris ADV, lida em 09/11/2026.

## O achado que define o desenho

A API do Projuris ADV é de **servidor para servidor**, e por isso o app não pode falar com ela:

| O que a documentação diz | Consequência |
|---|---|
| Autenticação `client_credentials` com um Client ID e um Client Secret **por escritório** | O segredo teria de ir dentro do app. Qualquer cliente o extrai do binário e passa a ler a carteira inteira do escritório. |
| A integração age como um "usuário da integração", com as permissões dele | Não existe escopo por empresa-cliente. Filtrar por `codigoPessoaEnvolvido` no app é filtro de tela, não de dado. |
| Limite de requisições **por escritório** (`429` + `Retry-After`) | Cem aparelhos de clientes esgotam a cota que o próprio escritório usa. |
| Não há campo de tradução nem de "exige o cliente?" | A regra que sustenta o produto não tem onde morar no Projuris. |
| Não há login de cliente final | O código de 6 dígitos por e-mail é nosso. |

Conclusão: **o adaptador do Projuris mora no backend.** O app fala com uma API só, a nossa, e é
cego ao provedor por construção. É isso que torna "outro escritório, outro provedor" uma troca de
adaptador no servidor, sem nova versão na loja.

```
 App iOS ──HTTPS──▶ API canônica (nossa) ──▶ Conector ──▶ Projuris ADV
 (uma marca)        auth do cliente           (porta)  ├─▶ outro sistema jurídico
                    isolamento por empresa             └─▶ DataJud / agregador
                    tradução + aprovação
                    cache e cota do provedor
```

## Onde fica a modularidade

**No backend — a porta do conector.** Um conector por provedor, todos devolvendo o modelo canônico:

```
Conector
  empresas(cnpj)                      → Empresa?            identifica o cliente no provedor
  casos(empresa, alteradosDesde)      → [Caso]
  andamentos(caso, alteradosDesde)    → [AndamentoBruto]    sempre guardado bruto, com origem
  compromissos(caso)                  → [Compromisso]       audiências e prazos
  arquivos(caso)                      → [Arquivo]
  enviarArquivo(caso, bytes, nome)    → Arquivo
  concluirCompromisso(id)             → Compromisso
  capacidades                         → Capacidades         o que este provedor sabe fazer
```

Todo registro guarda `origem { provedor, codigo }`. O app nunca vê o código do provedor: recebe
os identificadores do nosso banco. É o que permite trocar de fornecedor sem reconstruir histórico.

**No app — nenhuma peça conhece provedor:**

```
AdvClient/Core/Services/
  ServiceContainer              raiz de composição: demo, remoto ou indisponível
  SessionLifecycle              entrada, saída e volta ao primeiro plano (cache, token, ambiente)
  ProviderCapabilities          o que o escritório oferece; vem no snapshot
  UploadFile                    o arquivo com conteúdo, lido do fileImporter
  UnavailableServices           marca em "remote" com URL inválida: tudo falha, nada finge
  Remote/
    BackendAPI                  todas as chamadas do contrato v1
    SessionTokenStore           token no Keychain; é o AuthorizationProviding do LiveAPIClient
    RemoteAuthService           AuthService; códigos do servidor viram AuthError
    RemoteClientRepository      ClientDataRepository
    RemoteSessionLifecycle      os três ganchos do README, ligados
    DTO/                        tipos de fio, LossyList e o mapeamento para o domínio
```

Ligar uma marca à API é uma linha no `Brand.json` dela:

```json
"api": { "baseURL": "https://api.seuproduto.com.br", "mode": "remote" }
```

`AppState` recebe o `ServiceContainer`; `ClientDataRepository` e `AuthService` continuam sendo
as portas. Testes em `AdvClientTests/ServiceLayerTests.swift`.

## Contrato canônico v1 (app ⇄ nossa API)

| Chamada | Para quê | Cache |
|---|---|---|
| `POST /v1/auth/code` `{email}` | pede o código | — |
| `POST /v1/auth/session` `{email, code}` | troca o código por sessão, empresa e capacidades | — |
| `DELETE /v1/auth/session` | encerra a sessão | — |
| `GET /v1/snapshot` | casos, documentos, pendências, honorários, `syncedAt` | `.oneHour` |
| `POST /v1/cases/{id}/hearing/confirmation` | confirma presença | — |
| `POST /v1/pendencies/{id}/resolution` | resolve pendência | — |
| `POST /v1/documents?fileName&caseId` | envia arquivo (corpo cru) | — |
| `POST /v1/events/whatsapp-handoff` | registra a saída para o WhatsApp | — |

As três ações devolvem o snapshot atualizado, como o repositório mock já faz. Erros seguem o
`APIProblem` existente; quem ramifica é `code` — no acesso: `unknown_email`, `invalid_code`,
`code_expired`, `malformed_email`. 401 em qualquer chamada encerra a sessão no app.

Regras de fio que o app já cobra: datas em ISO 8601; dinheiro como texto decimal (`"84200.00"`);
enumerações como texto, com valor novo tolerado (área vira "Outros", risco desconhecido esconde a
provisão, pendência de tipo novo continua exigindo o cliente); um item malformado é descartado sem
derrubar a lista; `capabilities` ausente vale tudo ligado.

## Projuris ADV → modelo canônico

Serviços em `https://api.projurisadv.com.br/adv-service/`, token em
`https://apigw.projurisadv.com.br/auth/token` (8 h; reutilizar até vencer).

| Nosso modelo | Projuris | Observação |
|---|---|---|
| Empresa | `pessoa/consulta?filtro-geral={CNPJ}` | O CNPJ é a chave de casamento; guarda-se o `codigoPessoa`. |
| Caso | `POST processo/consulta-completa` com `codigoPessoaEnvolvido` e `atualizadoDesde` | `processoNumeroWs[principal]` → número CNJ; `segredoJustica` → sob sigilo; `situacaoProcesso` → aberto/encerrado; `responsaveis[0]` → advogado. |
| Parte contrária | `processo/{id}` → envolvidos | Página própria na documentação (Processos / Envolvidos). |
| Andamento (bruto) | `processo/{id}/andamento/consulta` | `descricaoAndamento` → texto oficial; `privado: true` **nunca** sai do backend. |
| Tradução, "exige o cliente?", aprovação | — | **Não existem.** Moram no nosso banco e no painel interno. Campos dinâmicos (`campoDinamicoDadoWs`) são alternativa se a equipe quiser escrever dentro do Projuris. |
| Audiência / prazo | `processo/{id}/tarefa/consulta-multi-modulo` | `compromisso`, `dataLimite`, `horaLimite`, `local`; `checklistWs` → "leve com você". |
| Confirmar presença | `PUT tarefa` (situação) ou andamento novo | Decidir com o escritório qual dos dois é o registro. |
| Documento | `processo/{id}/arquivo/` e `…/arquivo/visualiza/{id}` | O link público é gerado no backend, sob demanda. |
| Enviar arquivo | `POST arquivo` multipart + `modulos_vinculo` | |
| Contrato com vencimento e pontos de atenção | — | **Não há entidade de contrato na API.** A página "Contratos" da documentação são os tipos de dados. Fica no nosso banco. |
| Honorários | webhook de Receitas | Não há endpoint de consulta documentado. |

Detalhes que mordem: datas vêm em **milissegundos de época**, não ISO 8601; paginação por
`quan-registros` e `pagina`; consultas podem vir de cache de até 10 min (`X-Cache: HIT`);
os webhooks cobrem processos, receitas, despesas e solicitações — **não andamentos**, então
andamento é por varredura com `atualizadoDesde`.

## Quem cuida do login e das notificações

Os dois ficam com **o nosso servidor** (a API do produto). Nem o Projuris nem o CloudKit fazem
esse papel: o Projuris não tem login de cliente final, e a credencial dele só serve ao conector.
A Apple entrega as notificações, mas quem decide quando e o que mandar somos nós.

### Login

| Quem | Responsável por |
| --- | --- |
| App | Telas de e-mail e código; guardar o token da sessão no Keychain (`SessionTokenStore`, já pronto); Face ID |
| Nosso servidor | Gerar o código de 6 dígitos, limitar tentativas, emitir e revogar a sessão, aceitar só e-mails convidados, registrar cada acesso |
| Serviço de e-mail transacional | Entregar o código. O remetente usa o domínio do escritório, que precisa liberar o envio no próprio DNS |
| Escritório, pelo painel | Convidar quem pode entrar e tirar o acesso de quem saiu da empresa cliente |

O Face ID **não** autentica no servidor: ele só destrava o app no aparelho. Quem prova a
identidade é o código por e-mail; o token guardado é o que o servidor confere em cada chamada.
Revogar a sessão no painel derruba o cliente na próxima chamada (o app volta ao login em
qualquer `401`, já implementado). O Supabase Auth já oferece login por código de e-mail, o que
encurta essa parte da fundação.

### Notificações

| Quem | Responsável por |
| --- | --- |
| App | Pedir permissão depois do primeiro login, com o motivo na tela; mandar o token do aparelho ao servidor; apagar o registro ao sair da conta |
| Nosso servidor | Decidir quando notificar (só o que exige o cliente, no máximo uma por processo por dia, o resto em resumo semanal); montar o texto; enviar à Apple; apagar tokens que a Apple recusar |
| Apple (APNs) | Entregar a notificação no aparelho |
| Escritório | Gerar a chave de notificação (`.p8`) na própria conta Apple, porque cada marca é um app da conta do escritório; marcar "exige o cliente?" na fila de tradução, que é o que dispara a notificação |

Cuidados:

- **Texto sem conteúdo sigiloso.** A notificação aparece na tela bloqueada. Diga que há algo
  pendente e em qual caso, nunca o teor do andamento.
- **Uma chave por marca.** O servidor guarda, por escritório, a chave `.p8`, o Key ID, o Team ID
  e o bundle id da marca.
- **Android depois:** o envio fica atrás de uma porta única no servidor. Hoje ela fala direto com
  a APNs; com Android, entra o Firebase Cloud Messaging, que entrega nas duas plataformas.

Ainda falta no app e no contrato: registrar o token do aparelho (rota a acrescentar, como
`POST /v1/devices` e `DELETE /v1/devices/{token}`) e pedir a permissão de notificação, que o app
ainda não pede.

## Decisões em aberto

1. **Existe backend?** O estudo de implementação já prevê Postgres com isolamento por empresa.
   Sem ele não há como publicar com dados reais do Projuris.
2. **Onde a equipe escreve a tradução** — painel próprio ou campo dinâmico no Projuris.
3. **Contratos** — de onde vêm, já que o Projuris não os expõe.
4. **Confirmação de audiência** — conclusão de tarefa ou andamento.
5. **Conta de revisão da Apple** — o login é por código no e-mail, que o revisor não recebe. O
   backend precisa de um e-mail de revisão com código fixo, por marca.

## O que falta no app

- Renovação de token: hoje, vencido o token (8 h no Projuris; o nosso define o próprio prazo), o
  cliente volta ao login. A costura é `SessionTokenStore`.
- Barra de progresso real no envio (`URLSession.upload(for:from:delegate:)`).
- Avisar "sem conexão · dados de …" quando o snapshot vier do cache vencido (`Fetched.isStale`).
- Push: registrar o token de APNs no backend.
