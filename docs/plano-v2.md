# Plano da v2

Plano · 13/11/2026. Baseado em [camada-de-servico.md](camada-de-servico.md), [conectar-projuris.md](conectar-projuris.md), [custo-da-api.md](custo-da-api.md), [valor-do-produto.md](valor-do-produto.md) e [arquitetura-cloudkit-analise.md](arquitetura-cloudkit-analise.md).

## Resumo

A v2 tira o app da demonstração: ele passa a mostrar os processos reais do escritório, vindos do Projuris, com tradução aprovada pela equipe e notificação do que exige o cliente. A meta é um **piloto com um escritório e duas ou três empresas clientes**, depois de **13,5 a 18 semanas de trabalho** (cerca de R$ 81 mil a R$ 108 mil, mais 20% de reserva), e então a publicação da versão 2.0 na loja.

Ficam para depois do piloto, cada um com decisão própria: conversa no app e app do advogado (v2.1), Android e outros provedores jurídicos (v3).

## Onde a v1 parou

Estado em 13/11/2026:

- **Pronto e testado:** app iOS white label em modo demonstração, telas revisadas (navegação nativa, Dynamic Type, acessibilidade), cache de dados derivados, contrato v1 com a API implementado e testado do lado do app, capacidades por escritório, envio de arquivo com conteúdo, demonstração de pessoa física em nome do Jordan Neves, manifesto de privacidade, archive em Release passando. 160 testes.
- **Ainda não existe:** servidor, conector Projuris, painel da equipe, notificações.
- **Sem commit:** todo o trabalho desde a refatoração das telas está fora do git. Primeira tarefa da v2: commitar e marcar a v1 (`git tag v1.0`).

## Escopo

| | v2.0 (piloto e loja) | v2.1 (depois do piloto) | v3 |
| --- | --- | --- | --- |
| Servidor | Multi-inquilino, API v1 + rotas novas, conector Projuris, painel da equipe, push, auditoria | Conversa em tempo real | Outros provedores (Astrea, ADVBOX, DataJud) |
| App do cliente | Dados reais, notificações, sessão renovada, PDF do contrato, aviso de dado antigo | Conversa com o advogado, papéis de acesso por usuário, tema escuro | Android, iPad |
| App do advogado | Não | Se o piloto mostrar demanda | — |

Por que a conversa e o app do advogado ficam para a v2.1: o escopo da v1 cortou a conversa em 22/07/2026, e a análise do CloudKit mostrou que ela precisa do mesmo servidor da v2 para ter sigilo, controle do escritório e Android. Feita na v2.1, ela usa o tempo real do Supabase sobre o banco que a v2.0 já terá.

## Decisões antes de começar

Nenhuma linha do servidor deveria ser escrita antes destas respostas.

| Decisão | Quem decide | Trava |
| --- | --- | --- |
| Quem constrói e em que ritmo (você, você + um dev, fábrica) | Você | Prazo e custo |
| Plataforma do servidor (recomendado: Supabase, região São Paulo) | Você | Fase 1 |
| Onde a equipe escreve a tradução: painel nosso ou campo dinâmico no Projuris | Escritório | Fase 3 |
| De onde vêm os contratos com vencimento e pontos de atenção | Escritório | Fase 3 |
| Como confirmar presença: concluir tarefa ou registrar andamento | Escritório | Fase 2 |
| Conta de homologação no Projuris, com API e usuário da integração | Escritório | Fase 2 |
| Domínio da API e do e-mail dos códigos (DNS do escritório) | Escritório | Fase 1 |
| Quem revisa as traduções e quantos minutos por dia tem para isso | Escritório | Piloto |

## Entregas

| Fase | O que entrega | Semanas |
| --- | --- | ---: |
| 0. Preparação | Commit e tag da v1, decisões acima, conta de homologação do Projuris, projeto Supabase, medição de base no escritório (contatos de status por cliente) | 1 |
| 1. Fundação e API | Banco multi-inquilino com isolamento por escritório e empresa, login por código, sessões, arquivos, auditoria; as rotas da API v1 servindo dados de demonstração | 2,5 a 3,5 |
| 2. Conector Projuris | Token, varredura, mapeamento, webhooks, testes contra homologação; processos e andamentos reais chegando ao banco | 2,5 a 3,5 |
| 3. Painel, notificações e LGPD | Fila de tradução com rascunho por IA, publicação, contratos, documentos, convites e acessos; tarefas agendadas e envio de notificações; exportação, exclusão e retenção de dados | 5 a 7 |
| 4. App conectado | Marca em modo remoto, notificações, renovação de sessão, PDF, aviso de dado antigo, conta de revisão | 1,5 a 2 |
| 5. Piloto | Escritório + 2 a 3 empresas clientes por 4 semanas no TestFlight, com as métricas abaixo | 4 de calendário |
| 6. Loja | Ajustes do piloto, versão 2.0, revisão da Apple | 1 |

Trabalho total: 13,5 a 18 semanas (fases 0 a 4 e 6). As fases 1 e 2 podem correr em paralelo se houver duas pessoas. O piloto é tempo de calendário, não de desenvolvimento.

## O que fazer, por componente

### Servidor

- [ ] Esquema do banco: escritório, empresa cliente, usuário, caso, andamento (bruto e publicado), audiência, documento, contrato, pendência, honorário, dispositivo, trilha de acesso.
- [ ] Isolamento por linha no banco: um usuário só lê o que é da empresa dele; a equipe só o que é do escritório dela.
- [ ] Login por código: limite de tentativas, validade de 10 minutos, reenvio após 45 s, e-mail de revisão da Apple com código fixo por marca.
- [ ] API v1: as 8 rotas atuais, respondendo exatamente como `ServiceLayerTests.swift` espera.
- [ ] Rotas novas, sem quebrar a v1: `POST /v1/auth/refresh`, `POST /v1/devices`, `DELETE /v1/devices/{token}`.
- [ ] Regras portadas de `Rules.swift`, rodando os mesmos casos de `RulesTests.swift`.
- [ ] Conector Projuris conforme [conectar-projuris.md](conectar-projuris.md), com o texto bruto guardado e nada apagado.
- [ ] Rascunho de tradução com Claude Opus 5.5 e glossário por escritório.
- [ ] Tarefas agendadas: alertas 60/30/7 de contratos, pendências do dia, resumo semanal.
- [ ] Envio de notificação atrás de uma porta única (APNs hoje, Firebase quando houver Android), texto sem conteúdo sigiloso, uma por processo por dia.
- [ ] Exportação e exclusão de dados de um cliente (LGPD), política de retenção.
- [ ] Monitoramento de erros e alerta quando a varredura de um escritório falhar.

### Painel da equipe (web)

- [ ] Fila de tradução: original ao lado do rascunho, "exige o cliente?", aprovar e ir para o próximo pelo teclado.
- [ ] Publicar e despublicar andamentos.
- [ ] Cadastro de contratos: vencimento, renovação automática, prazo de aviso obrigatório quando renova sozinho, pontos de atenção.
- [ ] Publicar documentos para o cliente.
- [ ] Convidar e remover pessoas de cada empresa cliente; revogar sessões.
- [ ] Configuração do escritório: credenciais do Projuris (só gravação, nunca leitura), glossário, capacidades.

### App do cliente

- [ ] `Brand.json` da marca com `"mode": "remote"` e o endereço da API; tirar o e-mail pessoal do bloco `demo` antes da loja.
- [ ] Pedir permissão de notificação depois do primeiro login, com o motivo na tela; registrar e remover o token do aparelho.
- [ ] Abrir o caso certo ao tocar na notificação.
- [ ] Renovar a sessão em silêncio antes de vencer; voltar ao login só se a renovação falhar.
- [ ] Mostrar "sem conexão · dados de …" quando o snapshot vier do cache vencido.
- [ ] PDF do contrato com PDFKit a partir de link assinado de curta duração.
- [ ] Barra de progresso real no envio de arquivo.
- [ ] Só iPhone até existir layout de iPad (`TARGETED_DEVICE_FAMILY = 1`).
- [ ] `MARKETING_VERSION = 2.0`.

### Loja e conformidade

- [ ] Rótulos de privacidade no App Store Connect: e-mail, conteúdo enviado e interação, ligados à identidade, sem rastreamento.
- [ ] Declaração de criptografia (`ITSAppUsesNonExemptEncryption`).
- [ ] Política de privacidade do escritório cobrindo os dados reais.
- [ ] Conta de revisão com dados fictícios e as notas para o revisor.
- [ ] Contratos de tratamento de dados com os fornecedores (Supabase, envio de e-mail, Anthropic).

## Pronto para o piloto quando

- Um andamento novo no Projuris aparece na fila de tradução em até 1 hora.
- Um andamento aprovado aparece no app em até 1 minuto.
- Um cliente nunca vê processo de outra empresa (testado com duas empresas do mesmo escritório).
- Andamento privado ou sem aprovação nunca chega ao app.
- A notificação chega só para o que exige o cliente, no máximo uma por processo por dia.
- Confirmar presença e enviar arquivo chegam ao Projuris.
- O app aguenta ficar sem rede e diz de quando são os dados.
- Testes do app e do servidor passando; archive em Release passando.

## O que medir no piloto

Estas medidas validam as premissas de [valor-do-produto.md](valor-do-produto.md) e decidem a v2.1.

| Medida | Meta | Para decidir |
| --- | --- | --- |
| Contatos "como está meu processo?" por cliente por mês | Cair pela metade em relação à medição da Fase 0 | Preço e argumento de venda |
| Tempo de revisão por tradução | Até 3 minutos | Se o painel precisa de melhoria antes da loja |
| Andamentos publicados em até 24 h | 90% | Se a rotina da equipe se sustenta |
| Clientes que abrem o app por semana | Metade ou mais | Se o app tem uso real |
| Pedidos de conversa com o advogado | Contar | Se a v2.1 traz conversa e app do advogado |
| Sessões sem travamento | 99,5% | Se pode ir para a loja |

## Riscos

| Risco | Efeito | Como reduzir |
| --- | --- | --- |
| A equipe não sustenta a fila de tradução | App vazio; o produto perde o motivo | Rascunho por IA bom, fila rápida, medir na Fase 0 quem revisa e quanto tempo tem |
| API do Projuris diferente da documentação | Fase 2 atrasa | Conta de homologação na Fase 0; ler a página de Envolvidos antes |
| Limite de requisições do Projuris | Varredura lenta ou bloqueada | Varredura incremental, respeitar `Retry-After`, webhooks de processos |
| Revisão da Apple por funcionalidade mínima | Atraso na loja | Envio de arquivo e confirmação de presença funcionando na conta de revisão |
| Vazamento entre empresas | Incidente de LGPD e de sigilo | Isolamento no banco, não no app; teste com duas empresas antes do piloto |
| Uma pessoa só construindo | Prazo multiplica por 3 ou 4 em tempo parcial | Decidir o ritmo na Fase 0 e cortar escopo, nunca a fila de tradução |

## Custo

Servidor e painel: 10 a 14 semanas, R$ 60 mil a R$ 84 mil (detalhes em [custo-da-api.md](custo-da-api.md)). Somando a preparação (1 semana), o app conectado (1,5 a 2) e a ida para a loja (1), a v2 inteira fica em **13,5 a 18 semanas, cerca de R$ 81 mil a R$ 108 mil** a R$ 150 por hora, mais 20% de reserva. Operação: R$ 300 a R$ 400 por mês no primeiro escritório.
