# Jordan Neves — App do cliente (white-label)

App iOS (SwiftUI, iOS 17+, Xcode 16+) para os **clientes pessoa jurídica** do escritório
acompanharem processos, contratos e prazos. Base white-label: tudo que é da marca está isolado,
então um novo escritório entra como um novo target sem tocar no código das telas.

## Rodar

1. Abra `JordanNeves.xcodeproj` no Xcode 16 ou superior.
2. Selecione o scheme **JordanNeves** e um simulador de iPhone.
3. **Acesso de demonstração:** e-mail `financeiro@costalog.com.br`, código `492718`.
   Não há senha — o acesso é por código de 6 dígitos + Face ID.

Testes: `⌘U`, ou

```bash
xcodebuild test -project JordanNeves.xcodeproj -scheme JordanNeves -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Telas

| Jornada | Telas | Arquivos |
|---|---|---|
| Entrada | Abertura, 3 telas de valor, e-mail, código, Face ID | `Features/Onboarding/` |
| Painel | Posição jurídica, "exige você", notificações | `Features/Home/` |
| Processos | Lista, detalhe, andamento traduzido, audiência, confirmação | `Features/Cases/` |
| Documentos | Repositório, contrato com pontos de atenção, envio de arquivo | `Features/Documents/` |
| Perfil | Empresa, segurança, honorários, saída para o WhatsApp | `Features/Profile/` |

Fora do escopo por decisão de produto: assinatura eletrônica, agendamento de reunião e canal de
conversa dentro do app. O contato é um link `wa.me` com a mensagem já preenchida (empresa + número
do processo), em `Core/WhatsAppLink.swift`.

## As regras que sustentam o produto

Estão todas em `Core/Rules.swift`, como funções puras sobre um `now` recebido — é o que as torna
testáveis e impede que o painel, as notificações e a tela de documentos discordem sobre o que é
urgente.

1. **Publicação.** Nenhum andamento chega ao cliente sem tradução em português claro **e** aprovação
   humana registrada. `Rules.isPublished(_:)` é o guarda; nenhuma tela o contorna. É o que separa
   este app de um portal de consulta processual — e é trabalho diário da equipe, não do código.
2. **"Exige você" vs. "para saber".** O mesmo corte no painel, nas notificações, nos documentos e
   nos casos. Só o primeiro grupo gera push, com teto de um por caso por dia.
3. **Escalonamento 60/30/7.** Para contratos que renovam sozinhos, a conta é feita sobre o **prazo de
   aviso prévio**, não sobre o vencimento — é a data que realmente força uma decisão, e ela sempre
   vem antes.
4. **Prazo é data + contagem.** Sempre `14/09/2026 · em 54 dias`, em fonte monoespaçada tabular.
5. **Segredo de justiça** tem estado próprio: sem linha do tempo automática, com explicação. Sem
   isso o caso parece parado e gera o telefonema que o app existe para evitar.

## Arquitetura

- `App/Branding/` — o que é da marca: `Brand.json`, `Theme.swift` (tokens), `Components.swift`
  (design system), cores no catálogo de assets, logos e AppIcon. As cores **semânticas**
  (em dia / atenção / crítico) ficam em código de propósito: verde significa "sem pendência" para
  qualquer escritório, e deixar uma marca repintá-lo quebraria o significado.
- `App/Core/` — modelos, regras, formatadores e os protocolos `AuthService` / `ClientDataRepository`.
  As telas só conhecem os protocolos; hoje as implementações são `MockAuthService` e
  `MockClientRepository`, trocadas em `AppState`.
- `App/Features/` — uma pasta por jornada.
- `JordanNevesTests/` — 68 testes sobre as regras, o parser CNJ, o link do WhatsApp e o repositório.

O projeto usa pastas sincronizadas (`objectVersion 77`): arquivos novos em `App/` entram no target
automaticamente, sem editar o `.xcodeproj`.

## Backend (depois)

Implemente `ClientDataRepository` e `AuthService` contra a API real (URL base em `Brand.json` →
`api.baseURL`) e troque as instâncias em `AppState.swift`. Nenhuma tela muda.

A ingestão de andamentos tem duas fontes possíveis: a API pública do DataJud/CNJ (gratuita, em lote,
sem processos sigilosos) e um agregador comercial com webhook para os processos ativos com prazo.
O `ClientSnapshot.lastSyncedAt` é exibido ao cliente literalmente — o app nunca deve sugerir que os
dados são mais recentes do que são.

## Idiomas

Português (pt-BR, fonte) e inglês, via String Catalog (`App/Resources/Localizable.xcstrings`).
O app segue o idioma do aparelho e oferece a troca no Perfil.

Textos gerados fora do ambiente do SwiftUI — prazos, mensagens do WhatsApp, motivo do Face ID —
passam por `Format.string(_:locale:)`, que resolve contra o bundle da língua escolhida.
`String(localized:)` sozinho seguiria o idioma do **aparelho**, ignorando a troca no app.

## Capturas de tela em desenvolvimento

Builds de Debug aceitam `DEMO_ROUTE` para abrir direto em uma tela:

```bash
SIMCTL_CHILD_DEMO_ROUTE=contract xcrun simctl launch booted br.adv.jordanneves.app
```

Rotas: `onboarding`, `signIn`, `home`, `notifications`, `cases`, `caseDetail`, `sealedCase`,
`movement`, `hearing`, `documents`, `contract`, `upload`, `profile`. Compilado fora do Release.

## Fontes

A fonte da marca é **Montserrat** (Google Fonts), ainda não empacotada: baixe os `.ttf` e coloque em
`App/Resources/Fonts/`. São registrados no lançamento, sem mexer no Info.plist. Até lá o app usa a
fonte do sistema.

## Novo escritório white-label

1. Duplique o target **JordanNeves** e renomeie.
2. Troque `PRODUCT_BUNDLE_IDENTIFIER` e `INFOPLIST_KEY_CFBundleDisplayName`.
3. Crie a pasta da nova marca com `Brand.json`, `Assets.xcassets` (mesmos nomes: `BrandPrimary`,
   `BrandBrass`, `LogoHorizontal`, `AppIcon`, …) e fontes; ajuste o target membership.
4. Adicione um scheme. Nenhuma mudança no código das telas.

## Pendente

- Estados vazios e de erro de rede das quatro jornadas
- Papéis de acesso: hoje os três usuários da empresa veem tudo
- Painel interno da equipe (fila de tradução) — é o outro terço do produto e ainda não existe
- Renderizar o PDF do contrato com PDFKit a partir de URL assinada
