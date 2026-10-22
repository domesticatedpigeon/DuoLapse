import AppKit
import SwiftUI

struct RecorderView: View {
    @State private var model = RecorderModel()

    var body: some View {
        Group {
            if model.isScreenCaptureAllowed {
                RecorderForm(model: model)
            } else {
                ScreenRecordingPermissionView(onRequestAccess: model.requestScreenCaptureAccess)
            }
        }
        .frame(minWidth: 440, idealWidth: 480, minHeight: 380)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshScreenCapturePermission()
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
