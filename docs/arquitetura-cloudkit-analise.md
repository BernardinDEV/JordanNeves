# App cliente + app advogado com conversa no CloudKit: pontos fracos

Análise · 13/11/2026. Cenário avaliado: um teste limitado com dois apps no modelo da Uber (cliente e advogado, os advogados sob o perfil do escritório), toda a conversa entre cliente e advogado guardada no CloudKit e, se der certo, migração para outra plataforma por causa do Android.

## Resumo

Dá para testar esse modelo com CloudKit, mas ele cobra caro em três frentes: sigilo, controle do escritório sobre as conversas e a saída para Android. Para um teste limitado só em iPhone, é rápido e barato de montar. Se Android é um plano de verdade, é a opção mais cara de largar depois.

## Já pesam no teste limitado

**1. Exige conta iCloud ativa nos dois lados.** Sem iCloud no aparelho, a conversa não funciona. Isso pesa mais para os clientes, que são empresas:

- celulares corporativos com gerenciamento (MDM) às vezes bloqueiam iCloud;
- tem gente que usa um Apple ID pessoal no celular da empresa.

No teste, alguém vai ficar de fora logo no primeiro dia.

**2. Os dois apps precisam estar na conta Apple do escritório.** Um container do CloudKit pertence a uma equipe de desenvolvedor. O app do cliente e o app do advogado só compartilham dados se forem publicados pela mesma equipe. Como cada marca já fica na conta do próprio escritório (diretriz 4.2.6), cada escritório passa a ter dois apps e um container. Um "app do advogado" único, publicado por nós para todos os escritórios, não consegue ler o container de cada um.

**3. O banco público não serve para conversa sigilosa.** No banco público, a permissão vale por tipo de registro, não por registro: quem pode ler uma mensagem pode ler todas. Então a conversa precisa ficar em compartilhamento (CKShare), dentro da conta iCloud de alguém. E isso cria o problema seguinte.

**4. A conversa mora na conta pessoal de uma pessoa, não do escritório.**

- **Se o dono do compartilhamento for o advogado:** as mensagens ocupam o iCloud dele e saem do escritório quando ele sair.
- **Se o dono for o cliente:** o cliente pode apagar o histórico, e o escritório perde a prova.

É o mesmo problema que levou a trocar o WhatsApp pessoal pela conta Business do escritório, só que mais difícil de ver.

**5. O escritório não enxerga nada pelo servidor.** O acesso de servidor do CloudKit (as chaves server-to-server) só alcança o banco público. Conversas em compartilhamento ficam invisíveis para qualquer backend nosso. Então não dá para ter:

- painel do sócio;
- auditoria de quem respondeu o quê;
- busca;
- exportação para atender a LGPD;
- backup controlado pelo escritório.

**6. Não há regra rodando no servidor.** O CloudKit não tem gatilhos nem funções. Toda regra roda no aparelho, onde não é confiável:

- "esse advogado é desse escritório";
- "esse cliente só fala com o advogado do caso dele";
- o limite de notificações.

Também não há como mandar e-mail, juntar a conversa ao Projuris ou ao processo, nem registrar o rastro que hoje vai para o backend.

**7. A conversa não é em tempo real.** As notificações do CloudKit são push silencioso, e o iOS agrupa e atrasa esse tipo de push conforme o uso do aparelho. Com o app fechado, uma mensagem pode levar de segundos a minutos para aparecer, ou só aparecer quando o app abre. Para conversa, isso se percebe já na primeira semana.

**8. O TestFlight usa o ambiente de produção do CloudKit.** O esquema precisa estar publicado em produção antes do primeiro teste. Em produção, um campo já publicado não pode mais ser apagado ou ter o tipo trocado, só dá para acrescentar. Erros de modelagem do teste ficam para sempre.

**9. Hierarquia "escritório → advogados" não existe no CloudKit.** Não há organização nem papéis. Quem entra e sai do escritório, quem herda as conversas de um advogado que saiu e quem pode ver o quê teriam de ser controlados por um servidor nosso. Ou seja, o servidor que o CloudKit deveria poupar.

## Pesam quando der certo

**10. Migrar dos dados privados é por aparelho.** Como nenhum servidor consegue ler os compartilhamentos, migrar significa cada app subir o próprio histórico para o novo backend quando for aberto numa versão nova. Quem não atualizar fica com a conversa presa. Na prática, o histórico do teste não migra inteiro.

**11. Android é praticamente impossível.** O CloudKit tem uma versão web, mas exige login com Apple ID e não oferece notificação no Android. O plano "migra depois para atender Android" significa reescrever toda a camada de conversa e as notificações, e não trocar um adaptador.

**12. Cotas pouco claras.** Mensagens e anexos ocupam o iCloud do dono do compartilhamento. Um advogado com o iCloud cheio deixa de receber anexos, e o erro aparece para o cliente, não para ele.

**13. A revisão da Apple pode estranhar o app do advogado.** Um app usado só por funcionários costuma ir pela distribuição interna (Apple Business Manager ou listagem não pública), não pela loja aberta. Isso pode render perguntas na revisão. Não é um bloqueio certo, mas é um caminho a mais por escritório.

## O que muda em relação ao que já foi decidido

- **Conversa no app:** foi cortada em 22/07/2026 para reduzir escopo. Ela volta com caixa de entrada, notificação de mensagem nova e expectativa de prazo de resposta.
- **App do advogado:** não substitui bem o painel web da equipe. A fila de tradução no celular é lenta de operar, e o Projuris continua precisando de um servidor de qualquer jeito (ver [conectar-projuris.md](conectar-projuris.md)).

## Se mesmo assim for testar com CloudKit

- **Conversa atrás de um protocolo, como já é feito com os dados** (um `ConversationService`). A tela não pode saber que é CloudKit.
- **IDs de conversa e de mensagem próprios,** e não o `recordID` do CloudKit, para a migração não ter de remapear tudo.
- **Teste curto e descartável:** um escritório, dois advogados, cinco a dez clientes, com o combinado de que o histórico pode não migrar.
- **Medir o que decide a próxima fase:** atraso real das mensagens, quantos clientes não têm iCloud e quantas conversas por semana.

## Recomendação

Com custo parecido no teste, o Supabase, que o estudo de implementação já recomendava para o resto, entrega:

- tempo real;
- regras de acesso por linha no banco, com a hierarquia escritório → advogado;
- conversa em nome do escritório, visível para o painel;
- SDK oficial para Android.

E o backend que o Projuris já exige seria o mesmo.

Documentos relacionados: [camada-de-servico.md](camada-de-servico.md) · [conectar-projuris.md](conectar-projuris.md) · [valor-do-produto.md](valor-do-produto.md).
