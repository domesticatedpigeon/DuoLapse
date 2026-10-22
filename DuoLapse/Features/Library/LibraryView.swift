import SwiftUI

struct LibraryView: View {
    var body: some View {
        ContentUnavailableView(
            "No Timelapses",
            systemImage: "camera.aperture",
            description: Text("Timelapses you record will appear here.")
        )
        .frame(minWidth: 480, minHeight: 320)
    }
}

#Preview {
    LibraryView()
}
