# AdvClient — app do cliente para escritórios de advocacia (white label)

App iOS (SwiftUI, iOS 17+, Xcode 16+) para **clientes pessoa jurídica** acompanharem processos,
contratos e prazos. Um escritório é uma pasta em `Brands/` mais um target — o código das telas não
sabe qual marca está rodando.

Há duas marcas no repositório:

- **JordanNeves** — o escritório cliente.
- **Referencia** — marca neutra, sem escritório real. É o molde que `scripts/nova-marca.py` copia
  e o **host dos testes**: a suíte nunca depende do contrato visual de um cliente.

## Verificar sem Xcode

```bash
python3 scripts/verificar.py
```

Confere o `project.pbxproj`, os JSON e plists, as chaves de `Info.plist` que o código
exige em runtime, os assets que o núcleo pede de toda marca, o `Brand.json`, vazamento de
escritório no núcleo, o catálogo de strings nos dois idiomas e o manifesto de privacidade
(`AdvClient/Resources/PrivacyInfo.xcprivacy`, um só para todas as marcas): falha se o código usa
uma API de motivo obrigatório que ele não declara — o que voltaria do App Store Connect como
ITMS-91053. Dado novo que sai do aparelho também entra lá, e no rótulo de privacidade de cada
marca no App Store Connect. Sai com 1 se falhar, para
servir de passo de CI. Não substitui o build — pega a classe de erro que o compilador não pega.

## Rodar

1. Abra `AdvClient.xcodeproj` no Xcode 16 ou superior.
2. Escolha o scheme da marca (**JordanNeves**) e um simulador de iPhone.
3. **Acesso de demonstração:** e-mail `financeiro@costalog.com.br`, código `492718`.
   Não há senha — o acesso é por código de 6 dígitos + Face ID.
   Cada marca pode aceitar e-mails próprios na demonstração, com o mesmo código, em
   `"demo": { "invitedEmails": [...] }` no `Brand.json` (a marca JordanNeves aceita
   `jhordan.neves@hotmail.com`). O `Brand.json` vai dentro do app: não ponha ali e-mail que não
   possa ser visto por quem instalar.
   O mesmo bloco escolhe o conjunto de demonstração e o titular da conta:
   `"dataset": "personal"` troca a empresa do protótipo por uma conta de pessoa física (CPF,
   13 processos — de dois a três em cada estado, um em segredo de justiça, um encerrado —, contratos
   e documentos pessoais), e `"account": { "name", "document", "email" }` põe a conta em nome de
   alguém. A marca JordanNeves está assim, em nome de Jordan Neves. Os dados ficam em
   `AdvClient/Core/Demo/`; a marca de referência e os testes seguem com a empresa.

Antes de arquivar, compile em **Release** — é a configuração do archive, e o build de Debug e os
testes não a exercitam (código atrás de `#if DEBUG` some, mas as prévias `#Preview` continuam
sendo compiladas):

```bash
xcodebuild build -project AdvClient.xcodeproj -scheme JordanNeves -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

Testes rodam no scheme **Referencia**, não no da marca:

```bash
xcodebuild test -project AdvClient.xcodeproj -scheme Referencia \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Estrutura

```
AdvClient/            núcleo — não pode citar escritório nenhum
  AdvClientApp.swift  @main, ciclo de vida, bloqueio biométrico
  AppState.swift      estado observável, troca de idioma, sessão
  Branding/           BrandConfiguration (lê o Brand.json), Theme (tokens)
    Components/       um componente por arquivo: CaseCard, AppListRow, StatePill…
    Styles/           estilos de botão, superfície de cartão, checklist
  Core/               modelos, regras, formatadores, protocolos, segurança
    PortfolioIndex    tudo o que as telas derivam do snapshot, calculado uma vez
  Core/Networking/    camada de rede: cliente, padrão de erro, cache, endurecimento
  Features/           uma pasta por jornada; uma view por arquivo
    Navigation/       AppRoute — todo destino de lista, registrado uma vez por aba
    Shared/           aviso de falha de atualização, rodapé de sincronização
  Resources/          Localizable.xcstrings, InfoPlist.xcstrings

Brands/
  Referencia/         marca neutra: molde do script e host dos testes
  JordanNeves/
    Brand.xcconfig    bundle id, nome do app, pasta da marca, Team ID
    Info.plist        chaves de bundle da marca
    Resources/        sincronizado no target da marca:
      Brand.json      nome, contato, API, textos por idioma
      Assets.xcassets cores Brand*, logos, AccentColor, AppIcon
      Fonts/          .ttf da marca
      InfoPlist.xcstrings  Face ID em pt-BR e en; o Xcode extrai
                           CFBundleDisplayName para cá no primeiro build

Config/
  App.xcconfig        comum a todo target de aplicativo
  Tests.xcconfig      target de testes

AdvClientTests/       testes de regras, parser CNJ, link do WhatsApp, repositório e rede
scripts/nova-marca.py cria pasta + target + scheme de um escritório novo
```

O módulo Swift chama-se **AdvClient** para toda marca (`PRODUCT_MODULE_NAME` em
`Config/App.xcconfig`). É o que faz `@testable import AdvClient` valer para qualquer target e
dispensa duplicar a suíte de testes por escritório.

## Escritório novo

```bash
python3 scripts/nova-marca.py \
  --id silva-associados \
  --nome "Silva & Associados" \
  --razao "Silva & Associados Advogados" \
  --bundle br.adv.silvaassociados.app \
  --dominio silvaassociados.adv.br \
  --team ABCDE12345
```

O script cria `Brands/SilvaAssociados/`, injeta o target e o scheme no projeto e para por aí.
As cores nascem em **cinza neutro**, não copiadas de outra marca — copiar o catálogo do vizinho
economiza dois minutos e é assim que app de escritório chega à loja com a cor do concorrente.

Depois do script, falta preencher: as onze cores `Brand*`, os dois logotipos, o AppIcon de 1024 px,
os campos `DEFINIR` do `Brand.json` e as fontes. Nenhum arquivo de `AdvClient/` é tocado.

### A regra que sustenta isso

**Nenhum arquivo em `AdvClient/`, `Config/` ou no catálogo de strings do núcleo pode citar um
escritório.** Se você precisou escrever um nome, um telefone, um horário ou uma cor de marca fora de
`Brands/`, é vazamento — o lugar é o `Brand.json` ou o catálogo de assets da marca.

A única exceção é `TEST_HOST_TARGET` em `Config/Tests.xcconfig`: um target de testes precisa de um
app hospedeiro concreto. Os testes não olham para cor, logo ou nome.

Para conferir:

```bash
grep -rn "NomeDoEscritorio" AdvClient Config AdvClientTests
```

## Marca: o que é dado e o que é código

| Onde | O quê |
|---|---|
| `Brand.json` | nome, razão social, contato, horário, tagline, fonte, URL da API |
| `Assets.xcassets` da marca | `BrandPrimary`, `BrandSecondary`, `BrandMuted`, `BrandBody`, `BrandBackground`, `BrandCard`, `BrandOnBrand`, `BrandLine`, `BrandFill`, `BrandBrass`, `AccentColor`, logos, AppIcon |
| `Brand.xcconfig` | bundle id, nome sob o ícone, pasta da marca, Apple Developer Team ID |
| **Fica em código, de propósito** | verde/âmbar/vermelho de `Theme` e o verde do WhatsApp |

As cores semânticas não são configuráveis porque verde significa "sem pendência" para qualquer
escritório. Deixar uma marca repintá-lo quebraria o significado de que o app inteiro depende.

`BrandCard` e `BrandOnBrand` existem porque `.white` estava cravado em catorze telas: uma marca de
fundo creme não tinha como mudar, e a tinta sobre a cor da marca precisa escurecer quando a marca é
clara — contraste é acessibilidade, não gosto.

Texto que muda por escritório **e** por idioma usa `BrandText` no `Brand.json`:

```json
"businessHours": { "pt-BR": "seg a sex, 9h–18h", "en": "Mon–Fri, 9am–6pm" }
```

Resolve contra o idioma escolhido no app (`Format.uiLocale`), não o do aparelho.

## As regras que sustentam o produto

Estão em `Core/Rules.swift`, como funções puras sobre um `now` recebido — é o que as torna testáveis
e impede que painel, notificações e documentos discordem sobre o que é urgente.

1. **Publicação.** Nenhum andamento chega ao cliente sem tradução em português claro **e** aprovação
   humana registrada. `Rules.isPublished(_:)` é o guarda; nenhuma tela o contorna. É o que separa
   este app de um portal de consulta processual — e é trabalho diário da equipe, não do código.
2. **"Exige você" vs. "para saber".** O mesmo corte no painel, nas notificações, nos documentos e
   nos casos. Só o primeiro grupo gera push, com teto de um por caso por dia.
3. **Escalonamento 60/30/7.** Para contratos que renovam sozinhos, a conta é sobre o **prazo de
   aviso prévio**, não o vencimento — é a data que força a decisão, e vem sempre antes.
4. **Prazo é data + contagem.** Sempre `14/09/2026 · em 54 dias`, em mono tabular.
5. **Segredo de justiça** tem estado próprio: sem linha do tempo automática, com explicação.

## Telas

| Jornada | Telas | Arquivos |
|---|---|---|
| Entrada | Abertura, 3 telas de valor, e-mail, código, Face ID | `Features/Onboarding/` |
| Painel | Posição jurídica, "exige você", notificações | `Features/Home/` |
| Processos | Lista, detalhe, andamento traduzido, audiência | `Features/Cases/` |
| Documentos | Repositório, contrato, envio de arquivo | `Features/Documents/` |
| Perfil | Empresa, segurança, honorários, saída para o WhatsApp | `Features/Profile/` |

Fora do escopo por decisão de produto: assinatura eletrônica, agendamento e canal de conversa no
app. O contato é um link `wa.me` com mensagem preenchida, em `Core/WhatsAppLink.swift`.

## Idiomas

Português (pt-BR, fonte) e inglês, via String Catalog. O app segue o idioma do aparelho e oferece a
troca no Perfil. Textos gerados fora do SwiftUI passam por `Format.string(_:locale:)` —
`String(localized:)` sozinho seguiria o idioma do **aparelho**, ignorando a troca no app.

## Camada de rede

Fica em `AdvClient/Core/Networking/`. **Nenhuma tela, repositório ou serviço monta `URLRequest` por
conta própria** — cache com escopo de conta, bloqueio de ambiente comprometido, política de
redirecionamento e redação de log valem para o que passa por `APIClient`, e só. Uma chamada solta
com `URLSession.shared` contorna as quatro coisas de uma vez.

| Arquivo | O quê |
|---|---|
| `APIError.swift` | `APIProblem` (corpo de erro do serviço) e `APIError`, o único erro que a camada lança |
| `Endpoint.swift` | `HTTPMethod`, `HTTPBody`, `CachePolicy`, `Endpoint<Response>`, codificadores |
| `APIClient.swift` | protocolo, `Fetched<Value>`, transporte com nova tentativa, `LiveAPIClient` |
| `ResponseCache.swift` | cache de duas camadas: memória e disco criptografado |
| `NetworkSecurity.swift` | sessão endurecida, política de redirecionamento, portaria do ambiente |
| `NetworkLog.swift` | log redigido na origem |

```swift
let client = try LiveAPIClient.forCurrentBrand()
await client.setScope(company.id.uuidString)

let painel = try await client.send(
    Endpoint<PainelDTO>.get("/v1/painel", cache: .oneHour)
)

if painel.isStale {
    // Veio do que estava guardado: a tela tem que dizer desde quando.
    mostrarAviso(Format.string("network.stale.updatedAt \(Format.dateTime(painel.servedAt))"))
}
```

### O padrão de erro

Um `APIError` para tudo. `URLError`, `DecodingError` e `NSError` passam obrigatoriamente por
`APIError.mapping(_:)` antes de subir, e cada caso responde três perguntas sem `switch` espalhado
por tela:

- `userMessage` — a frase que o cliente lê, **no idioma escolhido no app**, sem status e sem inglês.
- `endsSession` / `isRetryable` / `allowsStaleFallback` — o que a tela faz.
- `diagnostic` — o que pode ir para o log: status, código estável e `requestID`. Nunca o corpo.

O texto que o servidor manda (`APIProblem.detail`) **não vai para a tela**: pode vir em inglês, pode
citar tabela, pode citar o CNPJ do cliente. Quem ramifica é `APIProblem.code`.

### O cache

Duas janelas por política, não uma:

| Política | Responde sem rede | Ainda serve se a rede cair | Onde |
|---|---|---|---|
| `.oneHour` | 1 hora | 1 dia | memória + disco |
| `.oneDay` | 1 dia | 7 dias | memória + disco |
| `.oneHourInMemory` | 1 hora | — | só memória |
| `.none` (padrão) | — | — | — |

A segunda janela existe porque este app mostra `lastSyncedAt` ao cliente literalmente. Sem rede, ele
responde com o que guardou marcado como `Fetched.source == .staleCache`, e a tela é **obrigada** a
dizer desde quando — dado de ontem, dito que é de ontem, é melhor do que uma tela vazia.

Só `GET` entra em cache. `URLCache` do sistema fica desligado: ele grava o corpo das respostas em
claro em `Library/Caches`, sem proteção de arquivo, e essa pasta entra em backup de aparelho. O
cache desta camada grava em `Application Support` com `NSFileProtectionComplete` (ilegível com o
aparelho bloqueado), fora do backup, e com a chave derivada de `SHA-256(versão | conta | chamada)` —
o nome do arquivo não diz de quem é o dado, e trocar de conta no mesmo aparelho não faz uma
responder pelo cache da outra.

### Segurança

Feito:

- **Sessão efêmera e endurecida** — sem `URLCache`, sem cookie, sem credencial guardada pelo
  sistema; TLS 1.2 no mínimo; falha rápido sem rede em vez de esperar em silêncio.
- **Redirecionamento** — só HTTPS para o mesmo host. É o vazamento clássico de token: `302` para
  outro domínio e o `URLSession` leva o `Authorization` junto. O salto recusado vira
  `APIError.insecureTransport`, que é um evento de segurança e não um detalhe de transporte.
- **Ambiente comprometido** — `SecurityGate` roda o `TamperDetection` fora da thread principal,
  guarda o veredito por cinco minutos e o revalida (quem acopla um depurador faz isso com o app já
  aberto). Comprometido: nenhuma requisição sai, o cache é apagado, a tela recebe
  `APIError.insecureEnvironment`.
- **Log redigido na origem** — sem parâmetros de consulta, sem corpo, sem cabeçalho, e a rota com
  identificador mascarado (`/v1/cases/{id}/movements`). Log de app iOS sai do controle do escritório
  no instante em que é escrito.
- **Sem repetição de `POST`** — nova tentativa automática só em método idempotente. Reenviar um
  `POST` que talvez tenha chegado é como o cliente acaba com dois envios do mesmo documento.

Falta, e é decisão consciente:

- **Pinning de certificado.** É o item que mais pesa numa auditoria e o único que de fato impede
  interceptação: sem ele, um proxy com CA instalada no aparelho lê o tráfego, e a detecção de proxy
  em `NetworkSecurity.isBehindHTTPProxy` é sinal de log, não defesa. Depende dos hashes SPKI do
  servidor. `RedirectPolicy` já é o lugar onde entra (`URLSessionDelegate`).
- **Token e renovação.** `AuthorizationProviding` é a costura; hoje `NoAuthorization`. A renovação
  em 401 precisa de uma única renovação concorrente para não virar tempestade de refresh, e isso
  depende do contrato do backend. Até lá, 401 derruba a sessão — que é o comportamento seguro.
- **Anti-replay e chave de idempotência** em `POST`/`PUT`.

### O que falta ligar no app

A camada está pronta e **não está conectada**: `AppState` continua com `MockAuthService` e
`MockClientRepository`. Três ganchos, quando for ligar:

```swift
// AppState.verify(...)  → depois de autenticar
await client.setScope(company.id.uuidString)

// AppState.signOut()    → obrigatório: chave com escopo evita colisão, não apagamento
await client.purgeCache()

// volta ao primeiro plano → força nova checagem do ambiente
await SecurityGate.shared.invalidate()
```

## Backend e provedores jurídicos

O app fala com **uma** API, a do produto. O provedor jurídico de cada escritório — Projuris ADV,
outro sistema, DataJud — fica atrás dela, num conector do servidor. A credencial desses provedores
abre a carteira inteira do escritório e não pode ir dentro de um app instalado por clientes.

O lado do app está pronto em `AdvClient/Core/Services/`; uma marca passa a usar a API com
`"mode": "remote"` no `Brand.json`. Desenho, contrato v1 e o mapeamento do Projuris em
[`docs/camada-de-servico.md`](docs/camada-de-servico.md).

### Fonte somente leitura de teste (`"mode": "readonly"`)

Para testar com processos reais antes de a API do produto existir. A marca Jordan Neves usa este
modo desde 13/11/2026, com a API de teste do Jordan: só leitura (`GET /app/v1/processos`), só os
processos dele.

- **A chave não entra no código nem no git.** Copie `Config/Secrets.example.xcconfig` para
  `Config/Secrets.xcconfig` (ignorado pelo git) e preencha `READONLY_API_BASE_URL` e
  `READONLY_API_KEY`. O build passa os dois para o `Info.plist`. As variáveis de ambiente
  `ADV_READONLY_API_BASE_URL` e `ADV_READONLY_API_KEY` do esquema do Xcode têm prioridade.
- **A chave viaja no app instalado** (no `Info.plist`). Serve para teste interno; uma marca em
  `readonly` não vai para a loja, e `scripts/verificar.py` avisa.
- Login de demonstração (mesmos e-mails e código). A fonte não separa clientes: mostra tudo o que a
  chave enxerga.
- O texto do andamento **não aparece** (regra 2): o app mostra só a data e a origem da última
  movimentação, com "explicação ainda não publicada". Parte contrária, valor, risco e advogado
  somem da tela, porque a fonte não informa. Documentos e envio ficam desligados.
- `atualizado_em` nulo: o app não mostra "Atualizado em …" em vez de inventar uma data.
- Chave recusada (401) aparece como falha de carga e não derruba o login.
- Código em `AdvClient/Core/Services/ReadOnly/`; testes em `AdvClientTests/ReadOnlySourceTests.swift`.
  Para voltar à demonstração, `"mode": "demo"` no `Brand.json`.

Outros documentos em `docs/`:

| Arquivo | O quê |
| --- | --- |
| [`app/README.md`](docs/app/README.md) | **Documentação do app**: telas, arquitetura, rede e segurança, white label, desenvolvimento, publicação na loja |
| [`api/README.md`](docs/api/README.md) | **Documentação da API do produto**: convenções, autenticação, rotas, modelos, erros, servidor, evolução, OpenAPI |
| [`regras-do-produto.md`](docs/regras-do-produto.md) | As regras que app e servidor aplicam igual: publicação, estado do caso, 60/30/7, notificações |
| [`conectar-projuris.md`](docs/conectar-projuris.md) | Roteiro para ligar a API do Projuris: autenticação, mapeamento, sincronização, checklist |
| [`valor-do-produto.md`](docs/valor-do-produto.md) | Estimativa de quanto o app vale para um escritório e como cobrar |
| [`arquitetura-cloudkit-analise.md`](docs/arquitetura-cloudkit-analise.md) | Pontos fracos de um modelo app cliente + app advogado com conversa no CloudKit |
| [`custo-da-api.md`](docs/custo-da-api.md) | Custo de construir e manter a API do produto, vantagens e o que se reaproveita entre escritórios |
| [`plano-v2.md`](docs/plano-v2.md) | Plano da v2: escopo, decisões, fases, backlog, critérios do piloto, riscos e custo |
| [`resposta-relatorio-jordan.md`](docs/resposta-relatorio-jordan.md) | Resposta ao relatório de aprimoramentos do Jordan (13/11/2026): o que já se confirma, ajustes rápidos, efeito na v2 |
| [`apresentacao-proposta.md`](docs/apresentacao-proposta.md) | Roteiro da apresentação da proposta ao escritório: entregas, prazo, valores e economia estimada |

O `ClientSnapshot.lastSyncedAt` é exibido ao cliente literalmente — o app nunca deve sugerir que os
dados são mais recentes do que são. `Fetched.servedAt` é a fonte certa para ele quando a resposta
vier do cache.

## Capturas de tela em desenvolvimento

Builds de Debug aceitam `DEMO_ROUTE`:

```bash
SIMCTL_CHILD_DEMO_ROUTE=contract xcrun simctl launch booted com.LumaRaySoftware.jordannevesadvogados
```

O identificador é o `BRAND_BUNDLE_ID` do `Brand.xcconfig` da marca.

Rotas: `onboarding`, `signIn`, `code`, `home`, `notifications`, `cases`, `caseDetail`,
`sealedCase`, `movement`, `hearing`, `hearingConfirmed`, `documents`, `contract`, `upload`,
`uploadSent`, `contact`, `profile`. As rotas de aba abrem cada uma na sua aba.

## Revisão de 26/08/2026

Quatro frentes: aderência ao protótipo, corretude do código, higiene do white label e escopo
contra as instruções do projeto. Dez achados confirmados por leitura.

**Corrigidos**

| # | Onde | O quê |
|---|---|---|
| 1 | `Rules.swift` | `urgency(of:)` era aplicada à data do andamento, sempre passada; devolvia `.critical` e a condição virava só `requiresClient`. Processo parado há meses aparecia como prazo próximo e `.withCourt` era inalcançável. Passou a olhar recência. |
| 2 | `SignInFlow.swift` | `BiometricOptInStep` era inalcançável: `verify()` grava a empresa e a `RootView` troca a árvore antes. O convite mudou para a `MainTabView`. |
| 3 | `AuthService.swift` | Expiração do código e cooldown de reenvio eram o mesmo relógio, de 60 s: o link só acendia com o código já morto. Agora 600 s e 45 s. |
| 4 | `Formatters.swift` | `date`, `weekdayDate` e `dateTime` tinham `brazil` como padrão e `money` era fixo em pt-BR. Seguem `Format.uiLocale`; a moeda continua BRL. |
| 5 | 11 arquivos | 42 `String(localized:)` resolviam contra o idioma do **aparelho**. Passaram por `Format.string`. |
| 8 | `Components.swift` | `CompassRose` era o logotipo do Jordan Neves desenhado no núcleo. Virou o asset `BrandMark`, por marca. |
| 10 | `Features/Contact/` | A tela de contato pedida nas instruções não existia. Existe, e renderiza os campos do `Brand.json` que nenhuma tela usava. |

**Abertos**

| # | Onde | O quê |
|---|---|---|
| 6 | `HearingSheet.swift:201` | ~~O `LOCATION` do `.ics` não escapa vírgula~~ — corrigido em 09/11/2026 (`HearingCalendarFile`). |
| 7 | `UploadSheet.swift:136` | ~~`dismiss()` direto após o envio viola a regra 5~~ — corrigido em 09/11/2026 (`UploadSentView`). |
| 9 | As duas marcas | Pedem Montserrat e nenhuma empacota `.ttf`; `Theme.brandFontAvailable` é sempre falso. |

Também levantado e não tratado: não há estados de erro de rede nas quatro jornadas (`AppState`
declara `loadFailed` e nenhuma tela o lê, e três ações engolem falhas com `try?`); a paleta escura
já está desenhada no protótipo mas `AdvClientApp` trava `.preferredColorScheme(.light)`; o build
declara iPad em `TARGETED_DEVICE_FAMILY` sem nenhuma adaptação de layout; `DeadlineLabel` foi criado
para a regra 4 e nunca é usado; duas linhas do perfil desenham chevron sem serem tocáveis.

## Refatoração de 09/11/2026 — telas, desempenho e usabilidade

Revisão das telas contra as diretrizes de SwiftUI e as Human Interface Guidelines.

**Usabilidade**

| Onde | O quê |
|---|---|
| As cinco abas | A barra de navegação estava escondida e o título era desenhado à mão. Voltou a ser a do sistema: título grande que recolhe, material, gesto de voltar. |
| `DocumentsView` | A busca existia no código e **não aparecia na tela** — `searchable` depende da barra que estava oculta. Agora fica sempre visível. O botão flutuante de envio virou item da barra. |
| `Theme.font` | Tamanho fixo: o app ignorava o Dynamic Type. Cada tamanho do protótipo agora escolhe o estilo de texto do sistema mais próximo e acompanha a preferência do aparelho. Cartões e linhas reorganizam o selo quando a letra está em tamanho de acessibilidade. |
| `HearingSheet`, `UploadSheet` | As ações engoliam falhas com `try?`: a tela dizia "presença confirmada" e "arquivo enviado" mesmo quando nada chegava ao escritório. Agora lançam, e a tela oferece tentar de novo. |
| `UploadSheet` | Fecha o achado nº 7: o envio termina numa confirmação que diz o que vem a seguir. |
| `HearingCalendarFile` | Fecha o achado nº 6: vírgula e ponto e vírgula escapados no `.ics`; horário em UTC. |
| `Format.dateTime` | Em inglês, 14h30 aparecia como `02h30` (relógio de 12 horas sem AM/PM). Datas e horas passaram a usar o fuso do escritório, o mesmo de `Rules.calendar`. |
| Painel, casos, documentos | `loadFailed` passou a ser lido: aviso no topo com a data do que está na tela e "Tentar de novo". Antes da primeira resposta aparece carregamento, não "nenhum caso". |
| Botões | "Confirmar presença", "Pular", "Agora não" e "Ver todos" só respondiam ao toque sobre o texto. A área de toque agora é o botão inteiro, com 44 pt. Cartões e linhas dão retorno ao toque. |
| `SignInFlow` | O passo do código é empilhado na navegação: voltar e arrastar da borda são os do sistema. A mensagem de código incorreto sumia no instante em que aparecia. |
| `AdvClientApp` | Com o app bloqueado, o VoiceOver ainda lia os processos por baixo da tela de bloqueio. |
| `ProfileView` | Linhas informativas perderam o chevron; a linha de idioma ganhou o rótulo que faltava. |
| `DocumentBadge` | O mesmo contrato aparecia como "Decidir" numa lista e "Renovar" em outra. Uma regra só: a palavra vem do contrato, a cor vem da urgência. |

**Desempenho**

| Onde | O quê |
|---|---|
| `PortfolioIndex` | As listas derivadas eram propriedades computadas do `AppState`: filtravam, ordenavam e reaplicavam as regras a cada leitura, várias vezes por atualização de tela. Agora são calculadas uma vez por snapshot (e ao voltar ao primeiro plano, porque dependem do dia). |
| `Theme.brandFontAvailable` | Fazia `UIFont(name:)` a cada chamada de `Theme.font` — centenas por atualização. Resolvido uma vez. |
| `AppState.refresh` | Login e primeira tela disparavam duas buscas simultâneas. Quem pede durante uma busca espera por ela. |
| `Format.money` | Um `NumberFormatter` novo por chamada virou `FormatStyle`. |
| `PositionBar` | `GeometryReader` trocado por um `Layout` proporcional. |

**Estrutura** — um tipo por arquivo, subviews como `View` próprias em vez de propriedades
computadas, ações fora do `body`, rota de navegação tipada (`AppRoute`) no lugar de `UUID` solto
e de destinos montados dentro do link.

**Não tratado aqui:** tema escuro, layout de iPad, fontes da marca (achado nº 9) e
`DeadlineLabel`, que continua sem uso.

## Pendente

- **Flags de recurso por escritório.** Um escritório sem repositório de documentos precisaria
  esconder a aba — mas o painel também navega para ela (`HomeView` → `selectedTab = .documents`),
  então a flag tem que cobrir os dois caminhos. Não foi feito pela metade de propósito.
- **Tema escuro.** `AdvClientApp` trava `.preferredColorScheme(.light)`. Agora que as superfícies
  são token, falta desenhar a paleta escura e destravar.
- Estados vazios e de erro de rede das quatro jornadas
- Papéis de acesso: hoje os três usuários da empresa veem tudo
- Painel interno da equipe (fila de tradução) — o outro terço do produto
- Renderizar o PDF do contrato com PDFKit a partir de URL assinada
