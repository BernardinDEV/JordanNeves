import Foundation

enum MockData {
    static let client = Client(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Bernardo Frisso",
        cpf: "123.456.789-00",
        email: "bfrisso@icloud.com",
        phone: "+55 11 98888-7777"
    )

    private static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? .now
    }

    static let cases: [LegalCase] = [
        LegalCase(
            id: UUID(uuidString: "22222222-0000-0000-0000-000000000001")!,
            number: "0012345-67.2025.5.02.0011",
            titleKey: "mock.case1.title",
            area: .labor,
            status: .awaitingDecision,
            court: "11ª Vara do Trabalho de São Paulo",
            responsibleLawyer: "Dr. Jordan Neves",
            openedAt: date(2025, 3, 14),
            movements: [
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000001")!, date: date(2026, 5, 28), titleKey: "mock.case1.m4.title", detailKey: "mock.case1.m4.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000002")!, date: date(2026, 2, 10), titleKey: "mock.case1.m3.title", detailKey: "mock.case1.m3.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000003")!, date: date(2025, 9, 2), titleKey: "mock.case1.m2.title", detailKey: "mock.case1.m2.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000004")!, date: date(2025, 3, 14), titleKey: "mock.case1.m1.title", detailKey: "mock.case1.m1.detail")
            ]
        ),
        LegalCase(
            id: UUID(uuidString: "22222222-0000-0000-0000-000000000002")!,
            number: "1004321-89.2025.8.26.0100",
            titleKey: "mock.case2.title",
            area: .civil,
            status: .active,
            court: "3ª Vara Cível — Foro Central de São Paulo",
            responsibleLawyer: "Dra. Ana Couto",
            openedAt: date(2025, 8, 21),
            movements: [
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000005")!, date: date(2026, 6, 1), titleKey: "mock.case2.m3.title", detailKey: "mock.case2.m3.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000006")!, date: date(2026, 1, 15), titleKey: "mock.case2.m2.title", detailKey: "mock.case2.m2.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000007")!, date: date(2025, 8, 21), titleKey: "mock.case2.m1.title", detailKey: "mock.case2.m1.detail")
            ]
        ),
        LegalCase(
            id: UUID(uuidString: "22222222-0000-0000-0000-000000000003")!,
            number: "5001122-33.2024.4.03.6183",
            titleKey: "mock.case3.title",
            area: .socialSecurity,
            status: .appeal,
            court: "1ª Vara Previdenciária de São Paulo",
            responsibleLawyer: "Dr. Jordan Neves",
            openedAt: date(2024, 11, 5),
            movements: [
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000008")!, date: date(2026, 4, 17), titleKey: "mock.case3.m3.title", detailKey: "mock.case3.m3.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-000000000009")!, date: date(2025, 10, 30), titleKey: "mock.case3.m2.title", detailKey: "mock.case3.m2.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-00000000000A")!, date: date(2024, 11, 5), titleKey: "mock.case3.m1.title", detailKey: "mock.case3.m1.detail")
            ]
        ),
        LegalCase(
            id: UUID(uuidString: "22222222-0000-0000-0000-000000000004")!,
            number: "1009876-54.2023.8.26.0002",
            titleKey: "mock.case4.title",
            area: .family,
            status: .closed,
            court: "2ª Vara de Família e Sucessões de São Paulo",
            responsibleLawyer: "Dra. Ana Couto",
            openedAt: date(2023, 6, 12),
            movements: [
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-00000000000B")!, date: date(2025, 2, 20), titleKey: "mock.case4.m2.title", detailKey: "mock.case4.m2.detail"),
                CaseMovement(id: UUID(uuidString: "33333333-0000-0000-0000-00000000000C")!, date: date(2023, 6, 12), titleKey: "mock.case4.m1.title", detailKey: "mock.case4.m1.detail")
            ]
        )
    ]
}
