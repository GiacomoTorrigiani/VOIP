import SwiftUI

public struct KeypadButtonData: Identifiable {
    public let id: String
    public let primary: String
    public let secondary: String

    public init(primary: String, secondary: String = "") {
        self.id = primary
        self.primary = primary
        self.secondary = secondary
    }
}

public struct KeypadView: View {
    public var onDigitTap: (String) -> Void

    private let rows: [[KeypadButtonData]] = [
        [
            KeypadButtonData(primary: "1", secondary: ""),
            KeypadButtonData(primary: "2", secondary: "A B C"),
            KeypadButtonData(primary: "3", secondary: "D E F")
        ],
        [
            KeypadButtonData(primary: "4", secondary: "G H I"),
            KeypadButtonData(primary: "5", secondary: "J K L"),
            KeypadButtonData(primary: "6", secondary: "M N O")
        ],
        [
            KeypadButtonData(primary: "7", secondary: "P Q R S"),
            KeypadButtonData(primary: "8", secondary: "T U V"),
            KeypadButtonData(primary: "9", secondary: "W X Y Z")
        ],
        [
            KeypadButtonData(primary: "*", secondary: ""),
            KeypadButtonData(primary: "0", secondary: "+"),
            KeypadButtonData(primary: "#", secondary: "")
        ]
    ]

    public var body: some View {
        VStack(spacing: 14) {
            ForEach(rows, id: \.first?.id) { row in
                HStack(spacing: 24) {
                    ForEach(row) { item in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onDigitTap(item.primary)
                        }) {
                            VStack(spacing: 1) {
                                Text(item.primary)
                                    .font(.system(size: 32, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary)
                                if !item.secondary.isEmpty {
                                    Text(item.secondary)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .tracking(1.5)
                                } else {
                                    Spacer().frame(height: 11)
                                }
                            }
                            .frame(width: 76, height: 76)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                        }
                        .buttonStyle(KeypadButtonStyle())
                    }
                }
            }
        }
    }
}

private struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
