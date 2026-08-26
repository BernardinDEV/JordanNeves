import Foundation

/// Demo content for the Costa Log tenant — the same company that appears in the
/// design prototype.
///
/// Dates are generated relative to launch rather than hard-coded, so the demo
/// always shows a hearing that is genuinely a few days out and a contract that is
/// genuinely about to renew. Fixed dates would quietly rot into a screen full of
/// overdue items, and the App Store review account would show the app at its worst.
enum MockData {

    // MARK: Company

    static let company = Company(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        legalName: "Costa Log Transportes Ltda",
        tradeName: "Costa Log Transportes",
        cnpj: "14902336000108",
        userEmail: "financeiro@costalog.com.br"
    )

    // MARK: Date helpers

    private static var today: Date { Rules.calendar.startOfDay(for: .now) }

    private static func inDays(_ days: Int, hour: Int = 9, minute: Int = 0) -> Date {
        let day = Rules.calendar.date(byAdding: .day, value: days, to: today) ?? today
        return Rules.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func daysAgo(_ days: Int) -> Date { inDays(-days) }

    // MARK: Identifiers

    /// Stable identifier from a two-character hex suffix. Anything that is not
    /// valid hex would silently produce a nil UUID, so it fails loudly here.
    private static func id(_ suffix: String) -> UUID {
        precondition(
            suffix.count == 2 && suffix.allSatisfy(\.isHexDigit),
            "MockData.id espera dois dígitos hexadecimais, recebeu \(suffix)"
        )
        return UUID(uuidString: "22222222-0000-0000-0000-0000000000\(suffix)")!
    }

    static let laborCaseID = id("01")
    static let taxCaseID = id("02")
    static let civilCaseID = id("03")
    static let sealedCaseID = id("04")

    static let suzanoContractID = id("11")
    static let portocelContractID = id("12")
    static let warehouseContractID = id("13")
    static let fuelContractID = id("14")

    // MARK: Cases

    static var cases: [LegalCase] {
        [
            LegalCase(
                id: laborCaseID,
                number: "0012345-16.2025.5.17.0004",
                title: "Reclamação trabalhista — ex-motorista",
                area: .labor,
                court: "4ª Vara do Trabalho de Vila Velha",
                courtShort: "TRT-17",
                isUnderSeal: false,
                opposingParty: "J. R. da Silva",
                claimValue: 84_200,
                risk: .medium,
                provision: 32_000,
                responsibleLawyer: "Jordan Neves",
                openedAt: daysAgo(430),
                closedAt: nil,
                movements: [
                    CaseMovement(
                        id: id("A1"),
                        date: daysAgo(10),
                        officialText: """
                        Vistos. Defiro o pedido de redesignação formulado pela reclamada às fls. 214, \
                        ante a impossibilidade de comparecimento da testemunha arrolada. Redesigno a \
                        audiência de instrução. Intimem-se as partes. Cumpra-se.
                        """,
                        headline: "O juiz aceitou o pedido de adiamento",
                        translation: """
                        A audiência foi adiada e remarcada. Ninguém perdeu prazo e a estratégia \
                        continua a mesma. O adiamento foi pedido por nós para garantir a presença da \
                        testemunha do setor de logística.
                        """,
                        requiresClient: false,
                        approvedBy: "Jordan Neves",
                        approvedAt: daysAgo(10),
                        publishedAt: daysAgo(10),
                        reassuranceKey: "movement.reassurance.nothingToDo"
                    ),
                    CaseMovement(
                        id: id("A2"),
                        date: daysAgo(59),
                        officialText: "Juntada de contestação pela parte reclamada. Documentos anexados às fls. 98/213.",
                        headline: "Defesa da empresa protocolada",
                        translation: """
                        Protocolamos a defesa da empresa, com os cartões de ponto e o contrato de \
                        trabalho do período. Agora o juiz vai marcar a audiência para ouvir as \
                        testemunhas.
                        """,
                        requiresClient: false,
                        approvedBy: "Jordan Neves",
                        approvedAt: daysAgo(59),
                        publishedAt: daysAgo(59),
                        reassuranceKey: "movement.reassurance.nothingToDo"
                    ),
                    CaseMovement(
                        id: id("A3"),
                        date: daysAgo(72),
                        officialText: "Citação da parte reclamada realizada via sistema. Prazo para defesa: 15 dias.",
                        headline: "Empresa citada no processo",
                        translation: "A empresa foi oficialmente notificada do processo e o prazo para apresentar defesa começou a correr.",
                        requiresClient: false,
                        approvedBy: "Ana Couto",
                        approvedAt: daysAgo(72),
                        publishedAt: daysAgo(72)
                    ),
                    // Arrived from the court but nobody has translated it yet, so it
                    // must not reach the client. Proves the publication rule in the
                    // running app, not only in the tests.
                    CaseMovement(
                        id: id("A4"),
                        date: daysAgo(1),
                        officialText: "Certidão de decurso de prazo para manifestação sobre documentos juntados.",
                        translation: nil,
                        requiresClient: false,
                        approvedBy: nil,
                        publishedAt: nil
                    )
                ],
                hearing: Hearing(
                    id: id("71"),
                    date: inDays(5, hour: 14, minute: 30),
                    venue: "Fórum Trabalhista de Vila Velha",
                    address: "Av. Champagnat, 200 — Sala 3",
                    whoMustAttend: "1 representante com poderes + gerente de logística",
                    checklist: [
                        ChecklistItem(id: id("C1"), text: "Contrato social e procuração", isChecked: true),
                        ChecklistItem(id: id("C2"), text: "Cartão de ponto do período", isChecked: true),
                        ChecklistItem(id: id("C3"), text: "Documento com foto do representante", isChecked: false)
                    ],
                    confirmedAt: nil
                )
            ),

            LegalCase(
                id: taxCaseID,
                number: "0004821-06.2024.8.08.0035",
                title: "Execução fiscal — ICMS 2023",
                area: .tax,
                court: "2ª Vara da Fazenda Pública de Vitória",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Estado do Espírito Santo",
                claimValue: 216_800,
                risk: .high,
                provision: 96_000,
                responsibleLawyer: "Jordan Neves",
                openedAt: daysAgo(620),
                closedAt: nil,
                movements: [
                    CaseMovement(
                        id: id("B1"),
                        date: daysAgo(74),
                        officialText: "Conclusos os autos ao MM. Juiz para apreciação dos embargos à execução opostos pela executada.",
                        headline: "Embargos aguardando decisão do juiz",
                        translation: """
                        Nossos embargos já estão com o juiz para decisão. Não há prazo definido para \
                        essa análise — pode levar semanas. Enquanto isso a cobrança segue suspensa.
                        """,
                        requiresClient: false,
                        approvedBy: "Jordan Neves",
                        approvedAt: daysAgo(74),
                        publishedAt: daysAgo(74),
                        reassuranceKey: "movement.reassurance.waitingCourt"
                    ),
                    CaseMovement(
                        id: id("B2"),
                        date: daysAgo(140),
                        officialText: "Recebidos os embargos à execução com efeito suspensivo. Intime-se a exequente para impugnação.",
                        headline: "Cobrança suspensa até o juiz decidir",
                        translation: """
                        O juiz aceitou analisar nossa contestação e suspendeu a cobrança até decidir. \
                        Foi a melhor notícia possível nesta fase: nada é bloqueado enquanto isso.
                        """,
                        requiresClient: false,
                        approvedBy: "Jordan Neves",
                        approvedAt: daysAgo(140),
                        publishedAt: daysAgo(140),
                        reassuranceKey: "movement.reassurance.nothingToDo"
                    )
                ],
                hearing: nil
            ),

            LegalCase(
                id: civilCaseID,
                number: "0009117-03.2026.8.08.0035",
                title: "Cobrança — Transportadora Serra Azul",
                area: .civil,
                court: "3ª Vara Cível de Vila Velha",
                courtShort: "TJES",
                isUnderSeal: false,
                opposingParty: "Transportadora Serra Azul Ltda",
                claimValue: 47_350,
                risk: .low,
                provision: nil,
                responsibleLawyer: "Ana Couto",
                openedAt: daysAgo(12),
                closedAt: nil,
                movements: [
                    CaseMovement(
                        id: id("D1"),
                        date: daysAgo(12),
                        officialText: "Distribuída a petição inicial por sorteio à 3ª Vara Cível. Custas recolhidas.",
                        headline: "Ação de cobrança protocolada",
                        translation: """
                        Entramos com a ação de cobrança contra a Serra Azul. O processo já tem número \
                        e vara definidos. O próximo passo é a citação da outra empresa.
                        """,
                        requiresClient: false,
                        approvedBy: "Ana Couto",
                        approvedAt: daysAgo(12),
                        publishedAt: daysAgo(12),
                        reassuranceKey: "movement.reassurance.nothingToDo"
                    )
                ],
                hearing: nil
            ),

            // Cases under seal receive no automated movements from any public
            // source. Without a state of its own this case would read as idle and
            // generate exactly the phone call the app exists to prevent.
            LegalCase(
                id: sealedCaseID,
                number: "0007233-51.2025.5.17.0009",
                title: "Reclamação trabalhista — assédio (segredo de justiça)",
                area: .labor,
                court: "9ª Vara do Trabalho de Vitória",
                courtShort: "TRT-17",
                isUnderSeal: true,
                opposingParty: "Sob sigilo",
                claimValue: 120_000,
                risk: .medium,
                provision: 45_000,
                responsibleLawyer: "Jordan Neves",
                openedAt: daysAgo(96),
                closedAt: nil,
                movements: [],
                hearing: nil
            )
        ]
    }

    // MARK: Documents

    static var documents: [ClientDocument] {
        [
            // Auto-renewing: the notice deadline is what actually forces a
            // decision, and it lands well before the contract itself expires.
            ClientDocument(
                id: suzanoContractID,
                title: "Transporte rodoviário — Suzano",
                kind: .contract,
                caseID: nil,
                counterparty: "Suzano S.A.",
                effectiveFrom: daysAgo(300),
                expiresAt: inDays(65),
                noticeDeadline: inDays(6),
                autoRenews: true,
                monthlyValue: 214_900,
                version: 2,
                attentionPoints: [
                    AttentionPoint(
                        id: id("91"),
                        clause: "Cláusula 9.1",
                        title: "Renovação automática por 24 meses",
                        detail: "Se ninguém avisar até a data-limite, o contrato se renova sozinho por dois anos nas mesmas condições.",
                        isWarning: true
                    ),
                    AttentionPoint(
                        id: id("92"),
                        clause: "Cláusula 12.4",
                        title: "Reajuste anual pelo IPCA",
                        detail: "Índice previsível e usual no setor. Sem teto, mas com histórico estável.",
                        isWarning: false
                    )
                ],
                uploadedByClient: false,
                uploadedAt: daysAgo(300),
                archivedAt: nil
            ),

            ClientDocument(
                id: portocelContractID,
                title: "Prestação de serviços — Portocel",
                kind: .contract,
                caseID: nil,
                counterparty: "Portocel Terminal Especializado",
                effectiveFrom: daysAgo(130),
                expiresAt: inDays(54),
                noticeDeadline: nil,
                autoRenews: false,
                monthlyValue: 128_400,
                version: 3,
                attentionPoints: [
                    AttentionPoint(
                        id: id("93"),
                        clause: "Cláusula 7.2",
                        title: "Reajuste por IPCA sem teto",
                        detail: "Em um ano de inflação alta, o custo sobe sem limite contratual. Vale negociar um teto na renovação.",
                        isWarning: true
                    ),
                    AttentionPoint(
                        id: id("94"),
                        clause: "Cláusula 14.1",
                        title: "Foro eleito: Vitória/ES",
                        detail: "Favorável — é a comarca da sua sede, o que reduz custo e tempo em caso de disputa.",
                        isWarning: false
                    )
                ],
                uploadedByClient: false,
                uploadedAt: daysAgo(130),
                archivedAt: nil
            ),

            ClientDocument(
                id: warehouseContractID,
                title: "Locação de galpão — Glória",
                kind: .contract,
                caseID: nil,
                counterparty: "Imobiliária Glória Ltda",
                effectiveFrom: daysAgo(200),
                expiresAt: inDays(140),
                noticeDeadline: nil,
                autoRenews: false,
                monthlyValue: 38_500,
                version: 1,
                attentionPoints: [],
                uploadedByClient: false,
                uploadedAt: daysAgo(200),
                archivedAt: nil
            ),

            ClientDocument(
                id: fuelContractID,
                title: "Fornecimento de combustível — Ipiranga",
                kind: .contract,
                caseID: nil,
                counterparty: "Ipiranga Produtos de Petróleo",
                effectiveFrom: daysAgo(90),
                expiresAt: inDays(220),
                noticeDeadline: nil,
                autoRenews: false,
                monthlyValue: 96_200,
                version: 1,
                attentionPoints: [],
                uploadedByClient: false,
                uploadedAt: daysAgo(90),
                archivedAt: nil
            ),

            ClientDocument(
                id: id("15"),
                title: "Procuração — audiência trabalhista",
                kind: .procedural,
                caseID: laborCaseID,
                counterparty: nil,
                effectiveFrom: daysAgo(8),
                expiresAt: nil,
                noticeDeadline: nil,
                autoRenews: false,
                monthlyValue: nil,
                version: 1,
                attentionPoints: [],
                uploadedByClient: false,
                uploadedAt: daysAgo(8),
                archivedAt: nil
            ),

            ClientDocument(
                id: id("16"),
                title: "Contrato social consolidado",
                kind: .corporate,
                caseID: nil,
                counterparty: nil,
                effectiveFrom: daysAgo(500),
                expiresAt: nil,
                noticeDeadline: nil,
                autoRenews: false,
                monthlyValue: nil,
                version: 4,
                attentionPoints: [],
                uploadedByClient: true,
                uploadedAt: daysAgo(500),
                archivedAt: nil
            )
        ]
    }

    // MARK: Pendencies

    static var pendencies: [Pendency] {
        [
            Pendency(
                id: id("E1"),
                kind: .hearing,
                title: "Confirmar presença na audiência",
                detail: "Audiência de instrução — presença obrigatória",
                dueDate: inDays(3),
                caseID: laborCaseID,
                documentID: nil,
                resolvedAt: nil
            ),
            Pendency(
                id: id("E2"),
                kind: .contractDecision,
                title: "Contrato Suzano: renovar ou avisar",
                detail: "Se ninguém avisar até a data-limite, renova sozinho por 24 meses.",
                dueDate: inDays(6),
                caseID: nil,
                documentID: suzanoContractID,
                resolvedAt: nil
            )
        ]
    }

    // MARK: Invoices

    static var invoices: [Invoice] {
        [
            Invoice(id: id("F1"), reference: "Honorários mensais", amount: 9_800, dueDate: inDays(14), paidAt: nil),
            Invoice(id: id("F2"), reference: "Honorários mensais", amount: 9_800, dueDate: daysAgo(16), paidAt: daysAgo(17)),
            Invoice(id: id("F3"), reference: "Honorários mensais", amount: 9_800, dueDate: daysAgo(46), paidAt: daysAgo(48))
        ]
    }
}
