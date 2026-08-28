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
escritório no núcleo e o catálogo de strings nos dois idiomas. Sai com 1 se falhar, para
servir de passo de CI. Não substitui o build — pega a classe de erro que o compilador não pega.

## Rodar

1. Abra `AdvClient.xcodeproj` no Xcode 16 ou superior.
2. Escolha o scheme da marca (**JordanNeves**) e um simulador de iPhone.
3. **Acesso de demonstração:** e-mail `financeiro@costalog.com.br`, código `492718`.
   Não há senha — o acesso é por código de 6 dígitos + Face ID.

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
  Branding/           BrandConfiguration (lê o Brand.json), Theme (tokens), Components
  Core/               modelos, regras, formatadores, protocolos, segurança
  Core/Networking/    camada de rede: cliente, padrão de erro, cache, endurecimento
  Features/           uma pasta por jornada
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

## Backend (depois)

Implemente `ClientDataRepository` e `AuthService` sobre o `APIClient` acima e troque as instâncias em
`AppState.swift`. Nenhuma tela muda.

O `ClientSnapshot.lastSyncedAt` é exibido ao cliente literalmente — o app nunca deve sugerir que os
dados são mais recentes do que são. `Fetched.servedAt` é a fonte certa para ele quando a resposta
vier do cache.

## Capturas de tela em desenvolvimento

Builds de Debug aceitam `DEMO_ROUTE`:

```bash
SIMCTL_CHILD_DEMO_ROUTE=contract xcrun simctl launch booted br.adv.jordanneves.app
```

Rotas: `onboarding`, `signIn`, `home`, `notifications`, `cases`, `caseDetail`, `sealedCase`,
`movement`, `hearing`, `documents`, `contract`, `upload`, `profile`.

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
| 6 | `HearingSheet.swift:201` | O `LOCATION` do `.ics` não escapa vírgula, que separa valores em iCalendar; endereço com vírgula chega truncado. |
| 7 | `UploadSheet.swift:136` | `dismiss()` direto após o envio viola a regra 5 — a confirmação não diz o que vem a seguir. A audiência faz certo. |
| 9 | As duas marcas | Pedem Montserrat e nenhuma empacota `.ttf`; `Theme.brandFontAvailable` é sempre falso. |

Também levantado e não tratado: não há estados de erro de rede nas quatro jornadas (`AppState`
declara `loadFailed` e nenhuma tela o lê, e três ações engolem falhas com `try?`); a paleta escura
já está desenhada no protótipo mas `AdvClientApp` trava `.preferredColorScheme(.light)`; o build
declara iPad em `TARGETED_DEVICE_FAMILY` sem nenhuma adaptação de layout; `DeadlineLabel` foi criado
para a regra 4 e nunca é usado; duas linhas do perfil desenham chevron sem serem tocáveis.

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
