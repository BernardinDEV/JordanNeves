import SwiftUI

/// Seis caixas, um campo só.
///
/// A single hidden field backs the boxes: iOS one-time-code autofill works, and
/// there is no focus juggling between six separate inputs. As caixas são
/// desenho; quem recebe o teclado e o VoiceOver é o campo.
struct OneTimeCodeField: View {
    @Binding var code: String
    let digitCount: Int
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        let digits = Array(code)

        ZStack {
            TextField("code.field.a11y", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused(isFocused)
                .opacity(0.001)

            HStack(spacing: 8) {
                ForEach(0..<digitCount, id: \.self) { index in
                    CodeDigitBox(
                        digit: index < digits.count ? digits[index] : nil,
                        isCursor: index == digits.count && isFocused.wrappedValue
                    )
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .contentShape(.rect)
        // Um gesto, não um botão: o controle de verdade é o campo acima, que o
        // VoiceOver já alcança. Isto só leva o toque nas caixas até ele.
        .onTapGesture(perform: focus)
    }

    private func focus() {
        isFocused.wrappedValue = true
    }
}
