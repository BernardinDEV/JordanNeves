import Foundation

/// Demonstração de uma conta de **pessoa física**: o cliente que contrata o
/// escritório para os próprios assuntos — imóveis alugados, herança, um
/// empregado doméstico, impostos, consumo.
///
/// Feita para mostrar o app inteiro numa só conta: de dois a três processos em
/// cada estado, um encerrado, um em segredo de justiça, contratos em cada
/// degrau do escalonamento 60/30/7 e um andamento ainda não traduzido (que não
/// pode aparecer). O nome e o CPF são neutros; a marca que quiser a conta em
/// nome de alguém troca a identidade no `Brand.json` (`demo.account`).
///
/// Como em `MockData`, as datas são relativas ao lançamento: a audiência está
/// sempre a poucos dias, e o "com o tribunal" está sempre parado há mais de 30.
enum PersonalMockData {

    static let account = Company(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        legalName: "Mariana Alves",
        tradeName: "Mariana Alves",
        // CPF fictício, com dígitos verificadores válidos.
        cnpj: "52998224725",
        userEmail: "mariana.alves@exemplo.com.br"
    )

    // MARK: Datas

    private static var today: Date { Rules.calendar.startOfDay(for: .now) }

    private static func inDays(_ days: Int, hour: Int = 9, minute: Int = 0) -> Date {
        let day = Rules.calendar.date(byAdding: .day, value: days, to: today) ?? today
        return Rules.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func daysAgo(_ days: Int) -> Date { inDays(-days) }

    // MARK: Identificadores

    private static func id(_ suffix: String) -> UUID {
        precondition(
            suffix.count == 2 && suffix.allSatisfy(\.isHexDigit),
            "PersonalMockData.id espera dois dígitos hexadecimais, recebeu \(suffix)"
        )
        return UUID(uuidString: "44444444-0000-0000-0000-0000000000\(suffix)")!
    }

    // Exige você
    static let evictionCaseID = id("01")
    static let estateCaseID = id("02")
    static let domesticLaborCaseID = id("03")
    // Prazo próximo
    static let propertyTaxCaseID = id("04")
    static let carLoanCaseID = id("05")
    static let leakCaseID = id("06")
    // Com o tribunal
    static let formerTenantCaseID = id("07")
    static let transferTaxCaseID = id("08")
    static let adversePossessionCaseID = id("09")
    // Em dia
    static let telecomCaseID = id("0A")
    static let incomeTaxCaseID = id("0B")
    static let sealedCaseID = id("0C")
    // Encerrado
    static let flightCaseID = id("0D")

    static let apartmentLeaseID = id("11")
    static let officeLeaseID = id("12")
    static let mortgageID = id("13")
    static let renovationID = id("14")

    /// Responsáveis do escritório. Nomes genéricos: o núcleo não cita escritório.
    private static let leadLawyer = "Ana Couto"
    private static let taxLawyer = "Rafael Lima"
    private static let familyLawyer = "Beatriz Moraes"

    // MARK: Processos

    static var cases: [LegalCase] {
        requiresYou + deadlineNear + withCourt + onTrack + closed
    }

    /// Três casos em "Exige você": uma audiência a confirmar e dois pedidos de
    /// documento (as pendências estão em `pendencies`).
    private static var requiresYou: [LegalCase] {
        [
            LegalCase(
                id: evictionCaseID,
                number: "0005012-80.2026.8.08.0035",
                title: "Ação de despejo — apartamento da Praia da Costa",
                area: .civil,
                court: "1ª Vara Cível de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "C. M. Ferreira (inquilino)",
                claimValue: 28_600,
                risk: .low,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(64),
                closedAt: nil,
                movements: [
                    movement(
                        "A1", daysAgo(9),
                        official: "Designo audiência de conciliação para a data indicada. Intimem-se as partes, que deverão comparecer pessoalmente.",
                        headline: "Audiência de conciliação marcada",
                        translation: """
                        O juiz marcou uma audiência para tentar um acordo com o inquilino. Sua \
                        presença é obrigatória: confirme no app e leve os comprovantes dos aluguéis \
                        em atraso. Se houver acordo, o processo pode terminar no mesmo dia.
                        """,
                        requiresClient: true,
                        by: leadLawyer
                    ),
                    movement(
                        "A2", daysAgo(41),
                        official: "Citado o réu. Decorrido o prazo sem purgação da mora.",
                        headline: "Inquilino citado e não pagou o atraso",
                        translation: """
                        O inquilino foi notificado oficialmente e não quitou os aluguéis no prazo \
                        que a lei dá. Isso fortalece o pedido de despejo.
                        """,
                        by: leadLawyer,
                        reassurance: "movement.reassurance.nothingToDo"
                    ),
                    // Chegou do tribunal e ninguém traduziu: não pode aparecer.
                    CaseMovement(
                        id: id("A3"),
                        date: daysAgo(1),
                        officialText: "Juntada de petição da parte ré requerendo prazo para desocupação voluntária.",
                        translation: nil,
                        requiresClient: false,
                        approvedBy: nil,
                        publishedAt: nil
                    ),
                ],
                hearing: Hearing(
                    id: id("71"),
                    date: inDays(4, hour: 10, minute: 0),
                    venue: "Fórum Cível de Vila Velha",
                    address: "Av. Champagnat, 200 — Sala 7",
                    whoMustAttend: "Você, pessoalmente (como locador)",
                    checklist: [
                        ChecklistItem(id: id("C1"), text: "Documento com foto", isChecked: true),
                        ChecklistItem(id: id("C2"), text: "Contrato de locação assinado", isChecked: true),
                        ChecklistItem(id: id("C3"), text: "Comprovantes dos aluguéis em atraso", isChecked: false),
                    ],
                    confirmedAt: nil
                )
            ),

            LegalCase(
                id: estateCaseID,
                number: "0003304-62.2025.8.08.0024",
                title: "Inventário — espólio de Helena Alves",
                area: .family,
                court: "2ª Vara de Família e Sucessões de Vitória",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Sem parte contrária (inventário consensual)",
                claimValue: 640_000,
                risk: .low,
                provision: nil,
                responsibleLawyer: familyLawyer,
                openedAt: daysAgo(210),
                closedAt: nil,
                movements: [
                    movement(
                        "B1", daysAgo(6),
                        official: "Intime-se a inventariante para juntar certidões de nascimento ou casamento atualizadas de todos os herdeiros, no prazo de 15 dias.",
                        headline: "Juiz pediu as certidões dos herdeiros",
                        translation: """
                        Para dividir os bens, o juiz precisa das certidões atualizadas de todos os \
                        herdeiros. Envie pelo app as que estiverem com você; as outras pedimos \
                        direto aos cartórios.
                        """,
                        requiresClient: true,
                        by: familyLawyer
                    ),
                    movement(
                        "B2", daysAgo(88),
                        official: "Apresentadas as primeiras declarações. Avaliação dos bens imóveis homologada.",
                        headline: "Avaliação dos imóveis aprovada",
                        translation: "O valor dos imóveis da herança foi aceito pelo juiz. Isso define o imposto (ITCMD) e a divisão.",
                        by: familyLawyer,
                        reassurance: "movement.reassurance.nothingToDo"
                    ),
                ],
                hearing: nil
            ),

            LegalCase(
                id: domesticLaborCaseID,
                number: "0001187-27.2026.5.17.0004",
                title: "Reclamação trabalhista — ex-empregada doméstica",
                area: .labor,
                court: "4ª Vara do Trabalho de Vila Velha",
                courtShort: "TRT-17",
                isUnderSeal: false,
                opposingParty: "R. S. Oliveira",
                claimValue: 31_400,
                risk: .medium,
                provision: 9_500,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(35),
                closedAt: nil,
                movements: [
                    movement(
                        "C4", daysAgo(5),
                        official: "Citação do reclamado. Prazo para apresentação de defesa até a audiência inicial.",
                        headline: "Você foi citado — vamos preparar a defesa",
                        translation: """
                        A ex-empregada cobra horas extras e férias. Para a defesa precisamos dos \
                        recibos de pagamento e do registro de ponto do período. Envie pelo app o que \
                        tiver; o eSocial nós consultamos daqui.
                        """,
                        requiresClient: true,
                        by: leadLawyer
                    ),
                ],
                hearing: nil
            ),
        ]
    }

    /// Três casos em "prazo próximo": o último andamento pede algo ao cliente,
    /// mas não há pendência aberta — o escritório está conduzindo.
    private static var deadlineNear: [LegalCase] {
        [
            LegalCase(
                id: propertyTaxCaseID,
                number: "0008841-40.2024.8.08.0035",
                title: "Execução fiscal — IPTU 2022",
                area: .tax,
                court: "Vara da Fazenda Pública Municipal de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Município de Vila Velha",
                claimValue: 7_820,
                risk: .medium,
                provision: 7_820,
                responsibleLawyer: taxLawyer,
                openedAt: daysAgo(400),
                closedAt: nil,
                movements: [
                    movement(
                        "D1", daysAgo(4),
                        official: "Rejeitada a exceção de pré-executividade. Prossiga-se a execução; intime-se o executado para pagamento ou garantia do juízo.",
                        headline: "Juiz manteve a cobrança do IPTU",
                        translation: """
                        O juiz não aceitou nosso argumento de que a cobrança estava prescrita. \
                        Vamos recorrer, mas para evitar bloqueio de conta o mais seguro é parcelar \
                        o débito enquanto isso. Vamos te ligar para decidir juntos.
                        """,
                        requiresClient: true,
                        by: taxLawyer
                    ),
                    movement(
                        "D2", daysAgo(150),
                        official: "Oposta exceção de pré-executividade pelo executado.",
                        headline: "Contestamos a cobrança",
                        translation: "Apresentamos a defesa alegando que a dívida de IPTU de 2022 já estava prescrita.",
                        by: taxLawyer,
                        reassurance: "movement.reassurance.nothingToDo"
                    ),
                ],
                hearing: nil
            ),

            LegalCase(
                id: carLoanCaseID,
                number: "0002290-43.2025.8.08.0024",
                title: "Revisional — financiamento do carro",
                area: .civil,
                court: "5ª Vara Cível de Vitória",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Banco Horizonte S.A.",
                claimValue: 18_900,
                risk: .low,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(280),
                closedAt: nil,
                movements: [
                    movement(
                        "D3", daysAgo(11),
                        official: "Deferida a prova pericial contábil. Nomeado perito. Partes intimadas para quesitos em 15 dias.",
                        headline: "Perícia contábil aprovada",
                        translation: """
                        Um perito vai recalcular os juros do financiamento. Ele pode pedir os \
                        extratos das parcelas pagas — se pedir, avisamos e você manda pelo app.
                        """,
                        requiresClient: true,
                        by: leadLawyer
                    ),
                ],
                hearing: nil
            ),

            LegalCase(
                id: leakCaseID,
                number: "0006610-69.2026.8.08.0035",
                title: "Indenização — vazamento do apartamento de cima",
                area: .civil,
                court: "2º Juizado Especial Cível de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "P. H. Santos",
                claimValue: 12_300,
                risk: .low,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(48),
                closedAt: nil,
                movements: [
                    movement(
                        "D4", daysAgo(16),
                        official: "Apresentada contestação. Vista à parte autora para réplica.",
                        headline: "Vizinho se defendeu — é a nossa vez",
                        translation: """
                        O vizinho diz que o vazamento veio do prédio, não do apartamento dele. Na \
                        resposta vamos usar o laudo do síndico. Se tiver fotos novas do teto, mande \
                        pelo app até sexta.
                        """,
                        requiresClient: true,
                        by: leadLawyer
                    ),
                ],
                hearing: nil
            ),
        ]
    }

    /// Três casos "com o tribunal": nada novo há mais de 30 dias, e ninguém —
    /// nem o escritório, nem o cliente — consegue acelerar.
    private static var withCourt: [LegalCase] {
        [
            LegalCase(
                id: formerTenantCaseID,
                number: "0004173-89.2025.8.08.0035",
                title: "Cobrança — aluguéis do ex-inquilino",
                area: .civil,
                court: "3ª Vara Cível de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "L. A. Rocha",
                claimValue: 22_750,
                risk: .low,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(330),
                closedAt: nil,
                movements: [
                    movement(
                        "A4", daysAgo(52),
                        official: "Encerrada a instrução. Autos conclusos para sentença.",
                        headline: "Processo pronto para a sentença",
                        translation: "Todas as provas já foram apresentadas. Agora é esperar o juiz decidir — não há prazo para isso.",
                        by: leadLawyer,
                        reassurance: "movement.reassurance.waitingCourt"
                    ),
                ],
                hearing: nil
            ),

            LegalCase(
                id: transferTaxCaseID,
                number: "0009025-29.2024.8.08.0024",
                title: "Mandado de segurança — ITBI do apartamento",
                area: .tax,
                court: "1ª Vara da Fazenda Pública Municipal de Vitória",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Secretário de Fazenda de Vitória",
                claimValue: 14_600,
                risk: .low,
                provision: nil,
                responsibleLawyer: taxLawyer,
                openedAt: daysAgo(520),
                closedAt: nil,
                movements: [
                    movement(
                        "A5", daysAgo(95),
                        official: "Remetidos os autos ao Tribunal de Justiça para julgamento da apelação.",
                        headline: "Recurso enviado ao Tribunal",
                        translation: """
                        Ganhamos na primeira instância (o ITBI foi cobrado sobre um valor acima do \
                        da compra). A prefeitura recorreu e o caso subiu para o Tribunal.
                        """,
                        by: taxLawyer,
                        reassurance: "movement.reassurance.waitingCourt"
                    ),
                ],
                hearing: nil
            ),

            LegalCase(
                id: adversePossessionCaseID,
                number: "0001420-88.2023.8.08.0049",
                title: "Usucapião — terreno em Guarapari",
                area: .civil,
                court: "1ª Vara Cível de Guarapari",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Herdeiros do antigo proprietário",
                claimValue: 180_000,
                risk: .medium,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(800),
                closedAt: nil,
                movements: [
                    movement(
                        "A6", daysAgo(140),
                        official: "Expedidos ofícios à União, ao Estado e ao Município para manifestação de interesse.",
                        headline: "Governo consultado sobre o terreno",
                        translation: """
                        É uma etapa obrigatória: União, Estado e Município dizem se têm interesse \
                        na área. Costuma demorar, e a resposta quase sempre é "sem interesse".
                        """,
                        by: leadLawyer,
                        reassurance: "movement.reassurance.waitingCourt"
                    ),
                ],
                hearing: nil
            ),
        ]
    }

    /// Três casos "em dia": movimento recente, nada pendente — e o de segredo
    /// de justiça, que não recebe andamento automático.
    private static var onTrack: [LegalCase] {
        [
            LegalCase(
                id: telecomCaseID,
                number: "0007733-05.2026.8.08.0035",
                title: "Cobrança indevida — operadora de telefonia",
                area: .civil,
                court: "1º Juizado Especial Cível de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Conecta Telecomunicações S.A.",
                claimValue: 6_400,
                risk: .low,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(20),
                closedAt: nil,
                movements: [
                    movement(
                        "B3", daysAgo(7),
                        official: "Citada a ré. Designada audiência de conciliação por videoconferência.",
                        headline: "Operadora notificada",
                        translation: """
                        A operadora foi citada. Vai haver uma audiência de conciliação por vídeo; \
                        nesse tipo de caso nós representamos você e sua presença não é necessária.
                        """,
                        by: leadLawyer,
                        reassurance: "movement.reassurance.nothingToDo"
                    ),
                ],
                hearing: nil
            ),

            LegalCase(
                id: incomeTaxCaseID,
                number: "5009812-44.2025.4.02.5001",
                title: "Restituição de IR — previdência privada",
                area: .tax,
                court: "3ª Vara Federal Cível de Vitória",
                courtShort: "TRF-2",
                isUnderSeal: false,
                opposingParty: "União (Fazenda Nacional)",
                claimValue: 43_200,
                risk: .low,
                provision: nil,
                responsibleLawyer: taxLawyer,
                openedAt: daysAgo(190),
                closedAt: nil,
                movements: [
                    movement(
                        "B4", daysAgo(21),
                        official: "Apresentada contestação pela União. Intime-se a parte autora para réplica.",
                        headline: "União contestou — resposta já em preparo",
                        translation: """
                        A União discorda da devolução, como esperado. A resposta é técnica e já \
                        está conosco; não precisamos de nada seu nesta fase.
                        """,
                        by: taxLawyer,
                        reassurance: "movement.reassurance.nothingToDo"
                    ),
                ],
                hearing: nil
            ),

            // Segredo de justiça: nenhuma fonte pública manda andamento. Sem um
            // estado próprio o caso pareceria parado.
            LegalCase(
                id: sealedCaseID,
                number: "0002601-98.2025.8.08.0035",
                title: "Revisão de pensão alimentícia (segredo de justiça)",
                area: .family,
                court: "1ª Vara de Família de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: true,
                opposingParty: "Sob sigilo",
                claimValue: 36_000,
                risk: .medium,
                provision: nil,
                responsibleLawyer: familyLawyer,
                openedAt: daysAgo(120),
                closedAt: nil,
                movements: [],
                hearing: nil
            ),
        ]
    }

    /// Um encerrado, para o filtro "Encerrados" não ficar vazio.
    private static var closed: [LegalCase] {
        [
            LegalCase(
                id: flightCaseID,
                number: "0003318-13.2025.8.08.0035",
                title: "Indenização — voo cancelado",
                area: .civil,
                court: "3º Juizado Especial Cível de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Aérea Sul Linhas Aéreas S.A.",
                claimValue: 8_000,
                risk: .low,
                provision: nil,
                responsibleLawyer: leadLawyer,
                openedAt: daysAgo(260),
                closedAt: daysAgo(38),
                movements: [
                    movement(
                        "B5", daysAgo(38),
                        official: "Comprovado o pagamento. Extinta a execução. Arquivem-se.",
                        headline: "Indenização paga — caso encerrado",
                        translation: "A companhia pagou os R$ 8.000 da condenação, e o valor já foi repassado para a sua conta.",
                        by: leadLawyer,
                        reassurance: "movement.reassurance.nothingToDo"
                    ),
                ],
                hearing: nil
            ),
        ]
    }

    // MARK: Documentos

    static var documents: [ClientDocument] {
        [
            // Renova sozinho: o prazo de aviso vence em dias e é o que força a decisão.
            contract(
                officeLeaseID,
                "Locação — sala comercial no Centro",
                counterparty: "Imobiliária Vitória Ltda",
                from: daysAgo(700), expires: inDays(40), notice: inDays(5), autoRenews: true,
                monthly: 3_900, version: 2,
                points: [
                    AttentionPoint(
                        id: id("91"), clause: "Cláusula 5.1",
                        title: "Renovação automática por 30 meses",
                        detail: "Se você não avisar até a data-limite, a locação se renova sozinha nas mesmas condições.",
                        isWarning: true
                    ),
                    AttentionPoint(
                        id: id("92"), clause: "Cláusula 8.3",
                        title: "Multa de três aluguéis na saída antecipada",
                        detail: "Usual no mercado, mas cai proporcionalmente ao tempo já cumprido.",
                        isWarning: false
                    ),
                ]
            ),
            // Vence em menos de 30 dias e não renova: "Renovar".
            contract(
                apartmentLeaseID,
                "Locação residencial — Praia da Costa",
                counterparty: "C. M. Ferreira",
                from: daysAgo(340), expires: inDays(25), notice: nil, autoRenews: false,
                monthly: 2_800, version: 1,
                points: [
                    AttentionPoint(
                        id: id("93"), clause: "Cláusula 3.2",
                        title: "Garantia por caução de três aluguéis",
                        detail: "A caução fica com você até a entrega das chaves e cobre parte do atraso cobrado no despejo.",
                        isWarning: false
                    ),
                ]
            ),
            contract(
                mortgageID,
                "Financiamento imobiliário — apartamento",
                counterparty: "Caixa Econômica Federal",
                from: daysAgo(1_400), expires: inDays(6_000), notice: nil, autoRenews: false,
                monthly: 4_120, version: 1,
                points: []
            ),
            contract(
                renovationID,
                "Prestação de serviços — reforma do apartamento",
                counterparty: "Obra Certa Reformas",
                from: daysAgo(30), expires: inDays(52), notice: nil, autoRenews: false,
                monthly: nil, version: 1,
                points: [
                    AttentionPoint(
                        id: id("94"), clause: "Cláusula 6",
                        title: "Sem multa por atraso da obra",
                        detail: "O contrato não prevê multa se a reforma atrasar. Vale pedir um aditivo antes da próxima parcela.",
                        isWarning: true
                    ),
                ]
            ),
            file(id("15"), "Procuração — ação de despejo", kind: .procedural, caseID: evictionCaseID, uploaded: daysAgo(62)),
            file(id("16"), "Certidão de óbito — Helena Alves", kind: .procedural, caseID: estateCaseID, uploaded: daysAgo(205), byClient: true),
            file(id("17"), "Declaração de Imposto de Renda 2026", kind: .corporate, caseID: nil, uploaded: daysAgo(180), byClient: true),
            file(id("18"), "Certidão de casamento", kind: .corporate, caseID: nil, uploaded: daysAgo(210), byClient: true),
        ]
    }

    // MARK: Pendências

    static var pendencies: [Pendency] {
        [
            Pendency(
                id: id("E1"), kind: .hearing,
                title: "Confirmar presença na audiência de conciliação",
                detail: "Ação de despejo — presença pessoal obrigatória",
                dueDate: inDays(2), caseID: evictionCaseID, documentID: nil, resolvedAt: nil
            ),
            Pendency(
                id: id("E2"), kind: .documentRequest,
                title: "Enviar certidões dos herdeiros",
                detail: "Nascimento ou casamento, atualizadas — o juiz deu 15 dias.",
                dueDate: inDays(9), caseID: estateCaseID, documentID: nil, resolvedAt: nil
            ),
            Pendency(
                id: id("E3"), kind: .documentRequest,
                title: "Enviar recibos e registro de ponto",
                detail: "Para a defesa na reclamação da ex-empregada doméstica.",
                dueDate: inDays(6), caseID: domesticLaborCaseID, documentID: nil, resolvedAt: nil
            ),
            Pendency(
                id: id("E4"), kind: .contractDecision,
                title: "Sala comercial: renovar ou avisar",
                detail: "Se ninguém avisar até a data-limite, renova sozinha por 30 meses.",
                dueDate: inDays(5), caseID: nil, documentID: officeLeaseID, resolvedAt: nil
            ),
        ]
    }

    // MARK: Honorários

    static var invoices: [Invoice] {
        [
            Invoice(id: id("F1"), reference: "Honorários — despejo", amount: 3_500, dueDate: inDays(10), paidAt: nil),
            Invoice(id: id("F2"), reference: "Honorários — inventário (2ª parcela)", amount: 6_200, dueDate: daysAgo(20), paidAt: daysAgo(21)),
            Invoice(id: id("F3"), reference: "Honorários — inventário (1ª parcela)", amount: 6_200, dueDate: daysAgo(50), paidAt: daysAgo(52)),
        ]
    }

    // MARK: Atalhos

    private static func movement(
        _ suffix: String,
        _ date: Date,
        official: String,
        headline: String,
        translation: String,
        requiresClient: Bool = false,
        by lawyer: String,
        reassurance: String? = nil
    ) -> CaseMovement {
        CaseMovement(
            id: id(suffix),
            date: date,
            officialText: official,
            headline: headline,
            translation: translation,
            requiresClient: requiresClient,
            approvedBy: lawyer,
            approvedAt: date,
            publishedAt: date,
            reassuranceKey: requiresClient ? nil : reassurance
        )
    }

    private static func contract(
        _ id: UUID,
        _ title: String,
        counterparty: String,
        from: Date,
        expires: Date,
        notice: Date?,
        autoRenews: Bool,
        monthly: Decimal?,
        version: Int,
        points: [AttentionPoint]
    ) -> ClientDocument {
        ClientDocument(
            id: id, title: title, kind: .contract, caseID: nil, counterparty: counterparty,
            effectiveFrom: from, expiresAt: expires, noticeDeadline: notice, autoRenews: autoRenews,
            monthlyValue: monthly, version: version, attentionPoints: points,
            uploadedByClient: false, uploadedAt: from, archivedAt: nil
        )
    }

    private static func file(
        _ id: UUID,
        _ title: String,
        kind: DocumentKind,
        caseID: UUID?,
        uploaded: Date,
        byClient: Bool = false
    ) -> ClientDocument {
        ClientDocument(
            id: id, title: title, kind: kind, caseID: caseID, counterparty: nil,
            effectiveFrom: nil, expiresAt: nil, noticeDeadline: nil, autoRenews: false,
            monthlyValue: nil, version: 1, attentionPoints: [],
            uploadedByClient: byClient, uploadedAt: uploaded, archivedAt: nil
        )
    }
}
