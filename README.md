# AdvClient — app do cliente para escritórios de advocacia (white label)

App iOS (SwiftUI, iOS 17+, Xcode 16+) para **clientes pessoa jurídica** acompanharem processos,
contratos e prazos. Um escritório é uma pasta em `Brands/` mais um target — o código das telas não
sabe qual marca está rodando.

Hoje há uma marca no repositório: **Jordan Neves Advogados**.

## Rodar

1. Abra `AdvClient.xcodeproj` no Xcode 16 ou superior.
2. Escolha o scheme da marca (**JordanNeves**) e um simulador de iPhone.
3. **Acesso de demonstração:** e-mail `financeiro@costalog.com.br`, código `492718`.
   Não há senha — o acesso é por código de 6 dígitos + Face ID.

Testes: `⌘U`, ou

```bash
xcodebuild test -project AdvClient.xcodeproj -scheme JordanNeves \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Estrutura

```
AdvClient/            núcleo — não pode citar escritório nenhum
  AdvClientApp.swift  @main, ciclo de vida, bloqueio biométrico
  AppState.swift      estado observável, troca de idioma, sessão
  Branding/           BrandConfiguration (lê o Brand.json), Theme (tokens), Components
  Core/               modelos, regras, formatadores, protocolos, segurança
  Features/           uma pasta por jornada
  Resources/          Localizable.xcstrings, InfoPlist.xcstrings

Brands/
  JordanNeves/
    Brand.xcconfig    bundle id, nome do app, pasta da marca
    Info.plist        chaves de bundle da marca
    Resources/        sincronizado no target da marca:
      Brand.json      nome, contato, API, textos por idioma
      Assets.xcassets cores Brand*, logos, AccentColor, AppIcon
      Fonts/          .ttf da marca

Config/
  App.xcconfig        comum a todo target de aplicativo
  Tests.xcconfig      target de testes

AdvClientTests/       68 testes sobre regras, parser CNJ, link do WhatsApp, repositório
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
  --dominio silvaassociados.adv.br
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
| `Brand.xcconfig` | bundle id, nome sob o ícone, pasta da marca |
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

## Backend (depois)

Implemente `ClientDataRepository` e `AuthService` contra a API real (`Brand.json` → `api.baseURL`) e
troque as instâncias em `AppState.swift`. Nenhuma tela muda.

O `ClientSnapshot.lastSyncedAt` é exibido ao cliente literalmente — o app nunca deve sugerir que os
dados são mais recentes do que são.

## Capturas de tela em desenvolvimento

Builds de Debug aceitam `DEMO_ROUTE`:

```bash
SIMCTL_CHILD_DEMO_ROUTE=contract xcrun simctl launch booted br.adv.jordanneves.app
```

Rotas: `onboarding`, `signIn`, `home`, `notifications`, `cases`, `caseDetail`, `sealedCase`,
`movement`, `hearing`, `documents`, `contract`, `upload`, `profile`.

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
