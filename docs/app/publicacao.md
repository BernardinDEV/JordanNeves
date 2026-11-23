# Publicação na App Store

Checklist · 23/11/2026. Parte da [documentação do app](README.md). Vale para cada marca: cada
escritório é um app separado na loja.

## Antes de arquivar

- [ ] Marca em `"mode": "remote"`, com o `baseURL` de produção. **Nunca** `readonly` (a chave
      viaja no app) nem `demo` (o revisor veria dados de exemplo como se fossem o produto).
- [ ] Bloco `demo` fora do `Brand.json`, ou ao menos sem e-mail pessoal: o arquivo é legível por
      quem instala.
- [ ] Contato real no `Brand.json`: telefone, WhatsApp, endereço, cidade, horário.
- [ ] `MARKETING_VERSION` atualizado (hoje `1.0` em `Config/App.xcconfig`; a v2 será `2.0`) e
      número de build novo.
- [ ] `TARGETED_DEVICE_FAMILY = 1` (só iPhone) enquanto não houver layout de iPad. Hoje está `1,2`,
      e a Apple revisa no iPad o que se declara para iPad.
- [ ] Fontes da marca empacotadas, ou `fontFamily` trocado para uma que exista.
- [ ] `python3 scripts/verificar.py` sem falhas e sem o aviso de modo.
- [ ] Testes passando no scheme `Referencia`.
- [ ] Build em **Release** passando ([comando](desenvolvimento.md#compilar-como-o-archive)).
- [ ] Trabalho commitado e marcado com a versão.

## Conta Apple

- [ ] Definir em que conta Apple Developer a marca é publicada. App de template publicado na conta
      do fornecedor pode esbarrar na diretriz 4.2.6 da App Store (apps gerados a partir de
      modelo); publicar na conta do escritório evita isso.
- [ ] `BRAND_DEVELOPMENT_TEAM` do `Brand.xcconfig` igual ao Team ID dessa conta.
- [ ] Chave de push (`.p8`) gerada nessa conta e entregue ao servidor ([`servidor.md`](../api/servidor.md#notificações)),
      quando as notificações existirem.

## App Store Connect

### Privacidade

O `AdvClient/Resources/PrivacyInfo.xcprivacy` vale para todas as marcas e declara:

| Dado | Ligado à identidade | Rastreamento | Finalidade |
| --- | --- | --- | --- |
| E-mail | sim | não | Funcionamento do app |
| Outro conteúdo do usuário (arquivos enviados) | sim | não | Funcionamento do app |
| Interação com o produto (saída para o WhatsApp) | sim | não | Funcionamento do app |

APIs de motivo obrigatório: `UserDefaults` (CA92.1, dados do próprio app).

- [ ] Rótulo de privacidade da marca no App Store Connect igual ao manifesto acima.
- [ ] Ao ligar push, acrescentar o identificador do aparelho (token de notificação) ao manifesto e
      ao rótulo.
- [ ] Política de privacidade do escritório publicada, com link no App Store Connect, cobrindo os
      dados reais que o app mostra e quem os trata ([LGPD](../api/servidor.md#lgpd)).

### Criptografia

- [ ] `ITSAppUsesNonExemptEncryption`: o app só usa HTTPS e a segurança do sistema; o normal é
      `NO`. A declaração é de quem publica.

### Revisão

O revisor da Apple não recebe o e-mail do código. Para cada marca:

- [ ] E-mail de revisão com código fixo, configurado no servidor e ligado a uma conta com **dados
      fictícios** ([`autenticacao.md`](../api/autenticacao.md#conta-de-revisão-da-apple)).
- [ ] O e-mail e o código nas notas para o revisor, com um roteiro curto: entrar, abrir um caso,
      confirmar uma audiência, enviar um arquivo.
- [ ] A conta fictícia com algo em cada aba: casos com andamentos, audiência a confirmar, contrato
      vencendo, documento, fatura. App que parece vazio é recusado por funcionalidade mínima.
- [ ] Explicar nas notas que o acesso é por convite do escritório (o app não tem cadastro aberto).
- [ ] "Excluir minha conta" existe no Perfil e leva o pedido ao escritório — a Apple exige o
      caminho de exclusão dentro do app.

### Página da loja

- [ ] Nome, subtítulo e descrição do escritório.
- [ ] Capturas de tela pelas rotas de captura ([`desenvolvimento.md`](desenvolvimento.md#capturas-de-tela)),
      com a demonstração — nunca com dados de cliente real.
- [ ] Categoria: Negócios. Classificação etária: 4+.
- [ ] URL de suporte e de marketing do escritório.

## TestFlight

- [ ] Grupo interno com a equipe do escritório antes de qualquer cliente.
- [ ] Piloto com duas ou três empresas clientes, em homologação, antes da loja
      ([plano da v2](../plano-v2.md)).

## Depois de publicar

- [ ] `store.appStoreID` no `Brand.json`.
- [ ] Monitorar travamentos pelo Xcode Organizer.
- [ ] Versão mínima no servidor, para quando for preciso obrigar a atualização
      ([`evolucao.md`](../api/evolucao.md#versão-mínima)).
