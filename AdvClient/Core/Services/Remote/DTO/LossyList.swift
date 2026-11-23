/// Uma lista do servidor em que um item malformado não derruba os outros.
///
/// Sem isto, um único documento com data quebrada fazia o snapshot inteiro
/// falhar na decodificação — e o cliente ficava sem os processos por causa de
/// um anexo.
struct LossyList<Element: Decodable & Sendable>: Decodable, Sendable {
    let elements: [Element]
    /// Quantos itens foram descartados. Vai para o log, nunca para a tela.
    let droppedCount: Int

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        var dropped = 0
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                elements.append(element)
            } else if (try? container.decodeNil()) == true
                        || (try? container.decode(DiscardedValue.self)) != nil {
                // Item pulado: o cursor andou. Sem isto o laço decodificaria o
                // mesmo item quebrado para sempre.
                dropped += 1
            } else {
                // Nada conseguiu consumir o item: para, em vez de travar.
                break
            }
        }
        self.elements = elements
        self.droppedCount = dropped
    }

    init(_ elements: [Element]) {
        self.elements = elements
        self.droppedCount = 0
    }
}

/// Consome qualquer valor JSON — objeto, texto, número — sem interpretá-lo.
private struct DiscardedValue: Decodable {
    init(from decoder: Decoder) throws {
        _ = try decoder.singleValueContainer()
    }
}
