# Desenvolvimento

Referência · 23/11/2026. Parte da [documentação do app](README.md).

## Requisitos

- Xcode 16 ou superior; iOS 17 ou superior no simulador ou aparelho.
- Python 3 para os scripts.
- Nenhuma dependência externa: nada de Swift Package, CocoaPods ou Carthage.

## Rodar

1. Abra `AdvClient.xcodeproj`.
2. Escolha o scheme da marca (**JordanNeves**) e um simulador de iPhone.
3. Rode.

A marca Jordan Neves está em `"mode": "readonly"`: sem `Config/Secrets.xcconfig`, o app entra mas
cada carga falha. Para ver a demonstração, ponha `"mode": "demo"` no `Brand.json` da marca, ou use
o scheme **Referencia**.

**Acesso de demonstração:** e-mail `financeiro@costalog.com.br`, código `492718`. Cada marca pode
aceitar e-mails a mais em `demo.invitedEmails`, com o mesmo código.

## Segredos

A chave da fonte somente leitura não entra no código nem no git:

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
```

Preencha `READONLY_API_BASE_URL` (escrito `https:/$()/servidor`, porque `//` começa comentário em
xcconfig) e `READONLY_API_KEY`. As variáveis de ambiente `ADV_READONLY_API_BASE_URL` e
`ADV_READONLY_API_KEY` do scheme têm prioridade. Detalhes em
[`../api/fonte-somente-leitura.md`](../api/fonte-somente-leitura.md).

## Verificar sem Xcode

```bash
python3 scripts/verificar.py
```

Pega a classe de erro que o compilador não pega. Sai com 1 se falhar, para servir de passo de CI.

| Checagem | O quê |
| --- | --- |
| Projeto | `project.pbxproj` coerente com as marcas |
| Formatos | JSON e plists válidos |
| Plists | Chaves de `Info.plist` que o código exige em runtime |
| Target sem ajustes | Nenhum ajuste da marca gravado no `project.pbxproj` (o Xcode faz isso pela aba General) |
| Assets | Tudo o que o núcleo pede de toda marca |
| `Brand.json` | Campos e tipos; avisa marca em `readonly` |
| Vazamento | Nome de escritório no núcleo |
| Localização | Toda chave nos dois idiomas |
| Privacidade | API de motivo obrigatório usada e não declarada no `PrivacyInfo.xcprivacy` — o que voltaria do App Store Connect como ITMS-91053 |

## Testar

Os testes rodam no scheme **Referencia**, não no da marca:

```bash
xcodebuild test -project AdvClient.xcodeproj -scheme Referencia \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

174 testes em 7 suítes; a lista está em [`arquitetura.md`](arquitetura.md#testes).

Ao mudar uma regra do produto, mude também [`../regras-do-produto.md`](../regras-do-produto.md) e
`RulesTests.swift` — o servidor porta esses casos.

Ao mudar o contrato com a API, mude `ServiceLayerTests.swift`, [`../api/modelos.md`](../api/modelos.md)
e [`../api/openapi.yaml`](../api/openapi.yaml) juntos.

## Compilar como o archive

O archive usa **Release**, e o build de Debug não o exercita (código atrás de `#if DEBUG` some, as
prévias `#Preview` continuam sendo compiladas):

```bash
xcodebuild build -project AdvClient.xcodeproj -scheme JordanNeves -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

## Capturas de tela

Builds de Debug aceitam `DEMO_ROUTE`, que abre uma tela direto, já com os dados de demonstração —
qualquer que seja o modo da marca:

```bash
SIMCTL_CHILD_DEMO_ROUTE=contract xcrun simctl launch booted com.LumaRaySoftware.jordannevesadvogados
```

O identificador é o `BRAND_BUNDLE_ID` do `Brand.xcconfig` da marca.

| Rota | Tela |
| --- | --- |
| `onboarding` | Apresentação |
| `signIn` | E-mail |
| `code` | Código |
| `home` | Início |
| `notifications` | Notificações |
| `cases` | Lista de casos |
| `caseDetail` | Detalhe do caso |
| `sealedCase` | Caso em segredo de justiça |
| `movement` | Andamento |
| `hearing` | Folha da audiência |
| `hearingConfirmed` | Presença confirmada |
| `documents` | Documentos |
| `contract` | Contrato |
| `upload` | Folha de envio |
| `uploadSent` | Arquivo enviado |
| `contact` | Contato |
| `profile` | Perfil |

Para capturar sem disputar o primeiro plano com outros apps, suba um simulador separado e use o
UDID dele no lugar de `booted`.

## Convenções de código

- **Um tipo por arquivo.** Subviews são `View` próprias, não propriedades computadas.
- **Ações fora do `body`.**
- **Regra em `Rules`**, derivado em `PortfolioIndex`, nunca dentro de view.
- **Texto pelo catálogo.** Fora do SwiftUI, `Format.string(_:)`; nunca `String(localized:)` sozinho.
- **Data, hora e dinheiro por `Format`**, no idioma do app e no fuso do escritório.
- **Rede só pelo `APIClient`.**
- **Ação que pode falhar lança.** Nada de `try?` em confirmar ou enviar: a tela precisa saber que
  falhou para não dizer que deu certo.
- **Nenhum escritório no núcleo** ([white label](white-label.md#a-regra)).
- **Comentários em português**, explicando o porquê.

## Controle de versão

Em 23/11/2026, todo o trabalho desde a refatoração de 09/11/2026 (camada de rede, serviços,
componentes, testes novos, `docs/`) está fora do git. O [plano da v2](../plano-v2.md) põe como
primeira tarefa: commitar e marcar a v1 (`git tag v1.0`).
