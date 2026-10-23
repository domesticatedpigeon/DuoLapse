import SwiftUI

extension ShapeStyle where Self == Color {
    static var brandPink: Color {
        Color("AccentColor", bundle: .main)
    }
}

extension View {
    func untinted() -> some View {
        tint(Color?.none)
    }
}
