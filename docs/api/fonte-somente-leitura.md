# Fonte somente leitura de teste

Referência · 23/11/2026. Parte da [documentação da API](README.md).

Uma API de teste, **separada da API do produto**, que o escritório disponibilizou para ver
processos reais no app antes de o servidor existir. A marca Jordan Neves usa este modo desde
13/11/2026 (`"mode": "readonly"` no `Brand.json`). Código em
`AdvClient/Core/Services/ReadOnly/`; testes em `AdvClientTests/ReadOnlySourceTests.swift`.

Não é para a loja: a chave viaja dentro do app instalado, e `scripts/verificar.py` avisa quando uma
marca está neste modo.

## A chamada

```http
GET /app/v1/processos HTTP/1.1
Host: {READONLY_API_BASE_URL}
Authorization: Bearer {READONLY_API_KEY}
Accept: application/json
```

Uma rota só. Sem login de cliente: o app entra com o login de demonstração e mostra tudo o que a
chave enxerga.

```json
{
  "atualizado_em": "2026-11-13T10:00:00-03:00",
  "total": 2,
  "processos": [
    {
      "numero_cnj": "5001234-56.2025.8.08.0035",
      "tribunal": "TJES",
      "orgao": "1º Juizado Especial Cível de Vila Velha",
      "classe": "Procedimento do Juizado Especial Cível",
      "polo": "ativo (autor)",
      "ultimo_andamento": {
        "data": "2026-10-03",
        "texto": "Juntada de petição",
        "fonte": "DataJud"
      }
    }
  ]
}
```

| Campo | Obrig. | O app |
| --- | --- | --- |
| `atualizado_em` | não | "Atualizado em …". Nulo: a linha não aparece, em vez de inventar uma data. |
| `total` | não | Ignorado |
| `processos[].numero_cnj` | sim | Precisa ter 20 dígitos; senão o processo é descartado. Gera o id estável do caso. |
| `tribunal` | não | Selo do cartão |
| `orgao` | não | Título do caso (ou a classe, ou o número) |
| `classe` | não | Linha "Classe"; ajuda a deduzir a área |
| `polo` | não | Linha "Sua posição" |
| `ultimo_andamento.data` | não | Data da última movimentação, com a `fonte` |
| `ultimo_andamento.texto` | não | **Não aparece.** Sem explicação do escritório, o texto do tribunal não chega ao cliente (regra 1). |

Área: pela classe quando ela diz (trabalhista, fiscal, família, cível); senão pelo segmento da
Justiça no número CNJ (`5` = trabalho); senão "Outros".

## O que fica de fora

Parte contrária, valor, risco, advogado, audiência, documentos, pendências e envio de arquivo — a
fonte não informa. As linhas somem da tela; a aba Documentos e o envio ficam desligados.

Chave recusada (`401`) aparece como falha de carga e **não** derruba o login, porque a chave é do
app, não da pessoa.

## Configurar

A chave não entra no código nem no git.

1. Copie `Config/Secrets.example.xcconfig` para `Config/Secrets.xcconfig` (ignorado pelo git).
2. Preencha `READONLY_API_BASE_URL` (em xcconfig, `https:/$()/servidor`) e `READONLY_API_KEY`.
3. Ou, no esquema do Xcode, as variáveis de ambiente `ADV_READONLY_API_BASE_URL` e
   `ADV_READONLY_API_KEY`, que têm prioridade.

Sem endereço ou chave, o app entra com o login de demonstração e cada carga falha dizendo que
falhou — nunca mostra dados de demonstração no lugar de processos reais.

Para voltar à demonstração: `"mode": "demo"` no `Brand.json`.
