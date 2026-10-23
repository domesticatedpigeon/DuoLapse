import DuoLapseCore
import SwiftUI
import UniformTypeIdentifiers

struct ExportFileSettings: View {
    @State private var settings = ExportPreferences.settings()
    @State private var outputFolder = ExportPreferences.outputFolder()
    @State private var isChoosingFolder = false

    var body: some View {
        Form {
            Section {
                Picker("Format", selection: $settings.codec) {
                    Text("HEVC (smaller file)").tag(ExportCodec.hevc)
                    Text("H.264 (plays everywhere)").tag(ExportCodec.h264)
                }
                .untinted()
                LabeledContent("Save to") {
                    HStack {
                        Text(outputFolder.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button("Choose…") { isChoosingFolder = true }
                            .buttonStyle(.glass)
                            .untinted()
                    }
                }
            }

            Section {
                TextField("File name", text: $settings.filenameTemplate.pattern)
                LabeledContent("Preview", value: settings.filenameTemplate.filename(for: .now) + ".mp4")
                Text("Use {YYYY}, {YY}, {MM}, {DD}, {hh}, {mm} and {ss} for the recording’s start date and time.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onChange(of: settings) { _, newSettings in
            var stored = ExportPreferences.settings()
            stored.codec = newSettings.codec
            stored.filenameTemplate = newSettings.filenameTemplate
            ExportPreferences.save(stored)
        }
        .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let folder) = result {
                outputFolder = folder
                ExportPreferences.save(outputFolder: folder)
            }
        }
        .onAppear {
            settings = ExportPreferences.settings()
            outputFolder = ExportPreferences.outputFolder()
        }
    }
}
