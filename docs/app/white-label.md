# White label: marcas

Referência · 23/11/2026. Parte da [documentação do app](README.md).

Um escritório é **uma pasta em `Brands/` mais um target e um scheme**. O código das telas não sabe
qual marca está rodando.

## A regra

**Nenhum arquivo em `AdvClient/`, `Config/` ou no catálogo de strings do núcleo pode citar um
escritório.** Nome, telefone, horário ou cor de marca fora de `Brands/` é vazamento: o lugar é o
`Brand.json` ou o catálogo de assets da marca. `scripts/verificar.py` procura vazamentos.

Única exceção: `TEST_HOST_TARGET` em `Config/Tests.xcconfig`, porque o target de testes precisa de
um app hospedeiro — a marca `Referencia`, neutra.

## A pasta de uma marca

```
Brands/JordanNeves/
  Brand.xcconfig          bundle id, nome sob o ícone, pasta, Team ID
  Info.plist              chaves de bundle da marca (ATS, Face ID, fonte somente leitura)
  Resources/              sincronizada no target da marca
    Brand.json            dados e textos do escritório
    Assets.xcassets       cores, marca gráfica, logotipos, ícone
    Fonts/                .ttf da marca
    InfoPlist.xcstrings   texto do Face ID em pt-BR e en; nome do app
```

| Onde | O quê |
| --- | --- |
| `Brand.json` | Nome, razão social, contato, horário, frase de apresentação, fonte, endereço e modo da API, demonstração |
| `Assets.xcassets` | 11 cores `Brand*`, `AccentColor`, `BrandMark`, `LogoHorizontal`, `LogoVertical`, `AppIcon` |
| `Brand.xcconfig` | `BRAND_ID`, `BRAND_DIR`, `BRAND_DISPLAY_NAME`, `BRAND_BUNDLE_ID`, `BRAND_DEVELOPMENT_TEAM` |
| **Fica no código, de propósito** | Verde, âmbar e vermelho de `Theme`; o verde do WhatsApp |

O target da marca **não pode ter ajuste próprio no `project.pbxproj`**: a aba General do Xcode grava
lá e sobrepõe o `Brand.xcconfig` em silêncio. `verificar.py` falha quando isso acontece. Mude
sempre no `Brand.xcconfig`.

## `Brand.json`

```json
{
  "id": "jordan-neves",
  "displayName": "Jordan Neves",
  "legalName": "Jordan Neves Advogados",
  "fontFamily": "Montserrat",
  "tagline": {
    "pt-BR": "Jurídico empresarial · Vila Velha/ES",
    "en": "Corporate law · Vila Velha, Brazil"
  },
  "contact": {
    "phone": "+55 27 0000-0000",
    "whatsapp": "+55 27 90000-0000",
    "email": "contato@exemplo.adv.br",
    "website": "https://exemplo.adv.br",
    "instagram": "https://instagram.com/exemplo",
    "linkedin": "https://linkedin.com/company/exemplo",
    "address": "Av. Exemplo, 1000 — Sala 101",
    "city": "Vila Velha — ES",
    "businessHours": { "pt-BR": "seg a sex, 9h–18h", "en": "Mon–Fri, 9am–6pm" }
  },
  "api": {
    "baseURL": "https://jordanneves.api.exemplo.com.br",
    "mode": "remote"
  },
  "demo": {
    "dataset": "personal",
    "account": { "name": "Nome do titular", "document": "000.000.000-00", "email": "titular@exemplo.com" },
    "invitedEmails": ["pessoa@exemplo.com"]
  },
  "store": { "appStoreID": null }
}
```

| Campo | Obrig. | Uso |
| --- | --- | --- |
| `id` | sim | Identificador em minúsculas |
| `displayName` | sim | Nome curto do escritório nas telas |
| `legalName` | sim | Razão social; abertura e Contato |
| `fontFamily` | sim | Família da fonte; sem o `.ttf` em `Fonts/`, o app usa a do sistema |
| `tagline` | sim | Frase de apresentação (texto por idioma) |
| `contact.phone`, `whatsapp`, `email`, `website`, `address`, `city` | sim | Tela de Contato; o `whatsapp` é o destino de todos os botões de WhatsApp |
| `contact.instagram`, `linkedin` | não | Linha some se ausente |
| `contact.businessHours` | sim | Texto por idioma |
| `api.baseURL` | sim | HTTPS. Um host por escritório ([por quê](../api/README.md#endereço-e-versão)). |
| `api.mode` | não | `demo` (padrão), `readonly` ou `remote` ([modos](README.md#modos-de-dados)) |
| `demo.dataset` | não | `business` (padrão, empresa de exemplo) ou `personal` (pessoa física: 13 processos, contratos e documentos pessoais) |
| `demo.account` | não | Põe a conta de demonstração em nome de alguém: `name`, `document` (CPF ou CNPJ), `email` |
| `demo.invitedEmails` | não | E-mails a mais aceitos na demonstração, com o mesmo código |
| `store.appStoreID` | não | Id da loja. Ainda sem uso no app; servirá para o aviso de "atualize o app" ([versão mínima](../api/evolucao.md#versão-mínima)) |

**Texto por idioma** (`BrandText`): pode ser um texto simples (vale para todos) ou um mapa por
idioma. Resolve contra o idioma escolhido **no app**, tentando `pt-BR`, `pt`, o texto simples e o
inglês, nessa ordem — nunca devolve vazio.

**O `Brand.json` vai dentro do app.** Qualquer um que instalar consegue lê-lo. Não ponha ali chave,
senha, nem e-mail pessoal que não possa ficar público. Em `remote`, o bloco `demo` é ignorado e
deve sair antes da loja.

## Cores

| Asset | Para quê |
| --- | --- |
| `BrandPrimary` | Cor principal: barra da abertura, botões, destaques |
| `BrandSecondary` | Apoio |
| `BrandMuted` | Texto secundário |
| `BrandBody` | Texto principal |
| `BrandBackground` | Fundo das telas |
| `BrandCard` | Superfície dos cartões |
| `BrandOnBrand` | Texto e ícone sobre `BrandPrimary` — escurece quando a marca é clara; contraste é acessibilidade |
| `BrandLine` | Divisórias |
| `BrandFill` | Preenchimentos neutros |
| `BrandBrass` | Detalhe metálico da marca |
| `AccentColor` | Cor de destaque do sistema |

As cores semânticas (verde "sem pendência", âmbar "atenção", vermelho "crítico") não são
configuráveis: o significado delas é o mesmo para qualquer escritório, e o app inteiro depende
dele.

## Imagens

| Asset | Para quê |
| --- | --- |
| `BrandMark` | Marca gráfica (símbolo) na abertura e no app, colorida pelo código |
| `LogoHorizontal`, `LogoVertical` | Logotipos completos |
| `AppIcon` | Ícone de 1024 px |

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

O script copia a marca `Referencia`, cria `Brands/SilvaAssociados/`, injeta o target e o scheme no
projeto e para por aí. As cores nascem em **cinza neutro**, nunca copiadas de outra marca — é assim
que app de escritório chega à loja com a cor do concorrente.

Depois do script, falta:

- [ ] as 11 cores `Brand*` e o `AccentColor`;
- [ ] `BrandMark`, os dois logotipos e o `AppIcon`;
- [ ] os campos `DEFINIR` do `Brand.json`;
- [ ] os `.ttf` da fonte em `Fonts/`;
- [ ] o texto do Face ID em `InfoPlist.xcstrings`, se o padrão não servir;
- [ ] `python3 scripts/verificar.py` sem falhas;
- [ ] do lado do servidor: o escritório, o host e a marca ([`servidor.md`](../api/servidor.md#escritório-novo)).

Nenhum arquivo de `AdvClient/` é tocado.

## Pendências do white label

- **Flags de recurso por escritório além das capacidades.** Esconder a aba Documentos já funciona
  pela API; outros recursos ainda não têm chave.
- **Fontes.** As duas marcas pedem Montserrat e nenhuma empacota o `.ttf`.
- **Tema escuro.** As superfícies já são tokens; falta desenhar a paleta escura de cada marca.
