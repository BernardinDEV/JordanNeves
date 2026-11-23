import Foundation

/// O arquivo `.ics` de uma audiência, entregue ao calendário do sistema como
/// `data:` URL — assim o app não pede permissão de calendário para um único
/// evento que o próprio cliente pediu para guardar.
enum HearingCalendarFile {

    /// Duração reservada no calendário. O tribunal não informa; duas horas
    /// cobrem a audiência e a espera no corredor.
    static let duration: TimeInterval = 2 * 3600

    static func ics(for hearing: Hearing, title: String) -> String {
        """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        DTSTART:\(stamp(hearing.date))
        DTEND:\(stamp(hearing.date.addingTimeInterval(duration)))
        SUMMARY:\(escape(title))
        LOCATION:\(escape("\(hearing.venue) — \(hearing.address)"))
        END:VEVENT
        END:VCALENDAR
        """
    }

    static func url(for hearing: Hearing, title: String) -> URL? {
        let encoded = Data(ics(for: hearing, title: title).utf8).base64EncodedString()
        return URL(string: "data:text/calendar;base64,\(encoded)")
    }

    /// Em iCalendar, vírgula e ponto e vírgula separam valores e a barra
    /// invertida é o escape (RFC 5545, 3.3.11). Sem isto, "Av. Princesa
    /// Isabel, 574" chegava ao calendário cortado na vírgula.
    static func escape(_ text: String) -> String {
        text
            .replacing("\\", with: "\\\\")
            .replacing(";", with: "\\;")
            .replacing(",", with: "\\,")
            .replacing("\r\n", with: "\\n")
            .replacing("\n", with: "\\n")
    }

    /// Instante em UTC (`…Z`). Horário "flutuante", sem fuso, seria lido no
    /// fuso do aparelho — e a audiência mudaria de hora para quem viaja.
    static func stamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }
}
