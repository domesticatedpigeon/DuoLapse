import Foundation
import Testing

@testable import DuoLapseCore

struct FilenameTemplateTests {
    let utc = TimeZone(identifier: "UTC")!
    let date = Date(timeIntervalSince1970: 1_761_145_385)

    @Test func defaultPatternMatchesMacOSScreenshotStyle() {
        #expect(FilenameTemplate().filename(for: date, timeZone: utc) == "DuoLapse Recording 2025-10-22 at 15.03.05")
    }

    @Test func expandsTwoDigitYear() {
        #expect(FilenameTemplate(pattern: "{YY}{MM}{DD}").filename(for: date, timeZone: utc) == "251022")
    }

    @Test func leavesWordsContainingTokenLettersAlone() {
        #expect(FilenameTemplate(pattern: "Summer MM notes").filename(for: date, timeZone: utc) == "Summer MM notes")
    }

    @Test func replacesColonsAndSlashes() {
        #expect(FilenameTemplate(pattern: "{hh}:{mm} a/b").filename(for: date, timeZone: utc) == "15.03 a-b")
    }

    @Test(arguments: ["", "   ", "..."])
    func fallsBackWhenNothingUsableRemains(pattern: String) {
        #expect(FilenameTemplate(pattern: pattern).filename(for: date, timeZone: utc) == "DuoLapse Recording")
    }

    @Test func removesLeadingDotsSoFileIsNotHidden() {
        #expect(FilenameTemplate(pattern: ".hidden").filename(for: date, timeZone: utc) == "hidden")
    }

    @Test func numbersCopiesWhenNameIsTaken() {
        let directory = URL(filePath: "/tmp/exports", directoryHint: .isDirectory)
        let taken: Set = ["Clip.mp4", "Clip 2.mp4"]
        let url = FilenameTemplate.availableURL(in: directory, baseName: "Clip", pathExtension: "mp4") {
            taken.contains($0.lastPathComponent)
        }
        #expect(url.lastPathComponent == "Clip 3.mp4")
    }
}
