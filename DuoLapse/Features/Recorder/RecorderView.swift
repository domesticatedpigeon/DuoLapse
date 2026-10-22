import AppKit
import SwiftUI

struct RecorderView: View {
    @State private var model = RecorderModel()

    var body: some View {
        RecorderForm(model: model)
            .frame(minWidth: 440, idealWidth: 480, minHeight: 480)
            .task {
                await model.refreshDevicesAndPermissions()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                Task { await model.refreshDevicesAndPermissions() }
            }
            .sheet(item: $model.exportingSession) { session in
                if let store = model.store {
                    ExportSheet(session: session, store: store)
                }
            }
            .alert("Something Went Wrong", isPresented: isShowingError, presenting: model.errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented { model.errorMessage = nil }
            }
        )
    }
}

#Preview {
    RecorderView()
}
