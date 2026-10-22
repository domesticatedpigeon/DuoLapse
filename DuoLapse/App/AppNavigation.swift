import Foundation
import Observation

enum LibrarySelection: Hashable {
    case newTimelapse
    case timelapse(UUID)
}

@Observable
final class AppNavigation {
    var selection: LibrarySelection? = .newTimelapse
    var exportRequestID: UUID?

    func show(_ id: UUID) {
        selection = .timelapse(id)
    }

    func requestExport(of id: UUID) {
        selection = .timelapse(id)
        exportRequestID = id
    }
}
