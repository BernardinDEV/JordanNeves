import Foundation

/// Do fio para o domínio. Cada decisão sobre valor desconhecido mora aqui, e
/// a regra é a mesma em todas: **nunca esconder algo que exige o cliente, e
/// nunca afirmar algo que o servidor não disse.**
extension SnapshotDTO {

    func domain() -> ClientSnapshot {
        ClientSnapshot(
            cases: cases.elements.compactMap { $0.domain() },
            documents: documents.elements.compactMap { $0.domain() },
            pendencies: pendencies.elements.map { $0.domain() },
            invoices: invoices.elements.compactMap { $0.domain() },
            lastSyncedAt: syncedAt,
            capabilities: capabilities.map {
                ProviderCapabilities(documents: $0.documents, uploads: $0.uploads)
            } ?? .all
        )
    }

    /// `"84200.00"` → 84200. Ponto como separador, sempre — é formato de fio,
    /// não de tela.
    static func money(_ text: String?) -> Decimal? {
        guard let text else { return nil }
        return Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))
    }
}

extension SnapshotDTO.Case {
    /// `nil` só quando o valor da causa não é um número: mostrar R$ 0,00 no
    /// lugar seria afirmar um valor que ninguém informou.
    func domain() -> LegalCase? {
        guard let claim = SnapshotDTO.money(claimValue) else { return nil }
        // Risco desconhecido: a linha de risco some (ela só aparece com
        // provisão), em vez de exibir um nível que o servidor não mandou.
        let knownRisk = risk.flatMap(RiskLevel.init(rawValue:))
        return LegalCase(
            id: id,
            number: number,
            title: title,
            area: PracticeArea(rawValue: area) ?? .other,
            court: court,
            courtShort: courtShort,
            isUnderSeal: underSeal,
            opposingParty: opposingParty,
            claimValue: claim,
            risk: knownRisk ?? .medium,
            provision: knownRisk == nil ? nil : SnapshotDTO.money(provision),
            responsibleLawyer: responsibleLawyer,
            openedAt: openedAt,
            closedAt: closedAt,
            movements: movements.elements.map { $0.domain() },
            hearing: hearing?.domain()
        )
    }
}

extension SnapshotDTO.Movement {
    func domain() -> CaseMovement {
        CaseMovement(
            id: id,
            date: date,
            officialText: officialText,
            headline: headline,
            translation: translation,
            requiresClient: requiresClient,
            approvedBy: approvedBy,
            approvedAt: approvedAt,
            publishedAt: publishedAt
        )
    }
}

extension SnapshotDTO.Hearing {
    func domain() -> Hearing {
        Hearing(
            id: id,
            date: date,
            venue: venue,
            address: address,
            whoMustAttend: whoMustAttend,
            checklist: checklist.map { ChecklistItem(id: $0.id, text: $0.text, isChecked: $0.checked) },
            confirmedAt: confirmedAt
        )
    }
}

extension SnapshotDTO.Document {
    func domain() -> ClientDocument? {
        let value = SnapshotDTO.money(monthlyValue)
        // Valor mensal presente e ilegível: descarta o documento em vez de
        // mostrar o contrato sem o valor, como se não tivesse.
        if monthlyValue != nil, value == nil { return nil }
        return ClientDocument(
            id: id,
            title: title,
            // Tipo novo: cai na pasta mais próxima, para o arquivo não sumir da
            // tela por falta de aba.
            kind: DocumentKind(rawValue: kind) ?? (caseId == nil ? .corporate : .procedural),
            caseID: caseId,
            counterparty: counterparty,
            effectiveFrom: effectiveFrom,
            expiresAt: expiresAt,
            noticeDeadline: noticeDeadline,
            autoRenews: autoRenews,
            monthlyValue: value,
            version: version,
            attentionPoints: attentionPoints.map {
                AttentionPoint(id: $0.id, clause: $0.clause, title: $0.title, detail: $0.detail, isWarning: $0.warning)
            },
            uploadedByClient: uploadedByClient,
            uploadedAt: uploadedAt,
            archivedAt: archivedAt
        )
    }
}

extension SnapshotDTO.Pendency {
    /// Nunca descartada: uma pendência é algo que exige o cliente. Tipo
    /// desconhecido vira o genérico "enviar/fazer algo", que ainda leva ao caso
    /// ou ao documento.
    func domain() -> Pendency {
        Pendency(
            id: id,
            kind: PendencyKind(rawValue: kind) ?? .documentRequest,
            title: title,
            detail: detail,
            dueDate: dueDate,
            caseID: caseId,
            documentID: documentId,
            resolvedAt: resolvedAt
        )
    }
}

extension SnapshotDTO.Invoice {
    func domain() -> Invoice? {
        guard let value = SnapshotDTO.money(amount) else { return nil }
        return Invoice(id: id, reference: reference, amount: value, dueDate: dueDate, paidAt: paidAt)
    }
}
