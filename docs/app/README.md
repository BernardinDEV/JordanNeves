# App do cliente — documentação

Referência · 23/11/2026. App iOS (SwiftUI) para os **clientes do escritório** — empresas e pessoas
físicas — acompanharem processos, contratos e prazos. Não é ferramenta da equipe do escritório nem
vitrine de captação.

White label: o núcleo `AdvClient/` serve a qualquer escritório; cada escritório é uma pasta em
`Brands/` e um target. A marca Jordan Neves é a primeira.

## Por onde começar

| Documento | O quê |
| --- | --- |
| Este arquivo | O que o app é, o que faz, estado atual |
| [`telas.md`](telas.md) | Cada jornada e cada tela: o que mostra, estados, ações |
| [`arquitetura.md`](arquitetura.md) | Camadas, estado, serviços, navegação, modos de dados |
| [`rede-e-seguranca.md`](rede-e-seguranca.md) | Camada de rede, cache, erros, proteção de dados no aparelho |
| [`white-label.md`](white-label.md) | Marca: `Brand.json`, cores, logos, `Brand.xcconfig`, escritório novo |
| [`desenvolvimento.md`](desenvolvimento.md) | Rodar, testar, verificar, capturar telas, segredos, release |
| [`publicacao.md`](publicacao.md) | Checklist da App Store: privacidade, revisão, versão |
| [`../regras-do-produto.md`](../regras-do-produto.md) | As regras de que todas as telas dependem |
| [`../api/README.md`](../api/README.md) | A API que o app consome |

O [README do repositório](../../README.md) tem o histórico das revisões e o início rápido.

## O que o app faz

Quatro jornadas, nesta ordem de importância:

1. **Acesso.** E-mail convidado pelo escritório, código de 6 dígitos, Face ID. Sem senha.
2. **Acompanhar processos.** Cada andamento chega traduzido em português claro e aprovado por
   alguém do escritório. O que exige o cliente aparece separado do que é só para saber.
3. **Documentos e contratos.** Contratos com vencimento e prazo de aviso visíveis, alertas
   60/30/7 dias, pontos de atenção marcados pelo advogado, envio de arquivo ao escritório.
4. **Falar com o advogado.** Um toque abre o WhatsApp do escritório com a mensagem já escrita: a
   empresa, o número do processo, o assunto.

Fora do escopo por decisão de produto: assinatura eletrônica, agendamento e conversa dentro do app
(as perguntas no caso estão em estudo para a v2; ver [`../api/evolucao.md`](../api/evolucao.md)).

## Números

| | |
| --- | --- |
| Plataforma | iPhone, iOS 17 ou superior; Xcode 16 ou superior |
| Linguagem | Swift 5, SwiftUI, Swift Concurrency, `@Observable` |
| Dependências externas | Nenhuma |
| Idiomas | Português (pt-BR, fonte) e inglês, com troca dentro do app |
| Telas | 5 abas, 17 rotas de captura |
| Testes | 174, em 7 suítes (Swift Testing) |
| Marcas no repositório | `JordanNeves` e `Referencia` (neutra, host dos testes) |

## Estado em 23/11/2026

| Parte | Estado |
| --- | --- |
| Telas das quatro jornadas, em pt-BR e inglês | Prontas, revisadas contra as Human Interface Guidelines |
| Dados de demonstração (empresa e pessoa física) | Prontos |
| Camada de rede com cache criptografado e segurança | Pronta, testada |
| Contrato v1 com a API do produto | Implementado e testado contra cliente falso; **o servidor não existe** |
| Fonte somente leitura de teste | Em uso pela marca Jordan Neves (`"mode": "readonly"`) |
| Notificações push | Não implementadas (não pede permissão, não registra o aparelho) |
| Renovação de sessão | Não implementada; sessão vencida volta ao login |
| PDF do contrato | Prévia desenhada; falta abrir o arquivo real |
| Tema escuro | Travado em claro até a paleta escura existir |
| iPad | Declarado no build, sem layout próprio — passar a só iPhone antes da loja |
| Fontes da marca | A marca pede Montserrat e não empacota o `.ttf`; o app usa a do sistema |
| Controle de versão | O trabalho desde a refatoração de 09/11/2026 está fora do git |

## Modos de dados

O `Brand.json` de cada marca escolhe de onde vêm os dados (`api.mode`):

| Modo | Dados | Login | Para quê |
| --- | --- | --- | --- |
| `demo` (padrão) | Embutidos no app | Código fixo para e-mails da demonstração | Demonstração, capturas, revisão de telas |
| `readonly` | API de teste do escritório | O da demonstração | Ver processos reais antes do servidor ([detalhes](../api/fonte-somente-leitura.md)) |
| `remote` | API do produto | Código por e-mail de verdade | Produção |

Nenhum modo cai em outro em silêncio: `remote` ou `readonly` mal configurado mostra falha em cada
carga, nunca dados de demonstração no lugar dos reais.
