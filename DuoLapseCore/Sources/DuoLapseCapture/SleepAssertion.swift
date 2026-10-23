import IOKit.pwr_mgt

final class SleepAssertion {
    private var assertionID: IOPMAssertionID?

    var isHeld: Bool {
        assertionID != nil
    }

    func hold(_ shouldHold: Bool) {
        if shouldHold, assertionID == nil {
            var newAssertionID = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertPreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "DuoLapse is recording a timelapse" as CFString,
                &newAssertionID
            )
            if result == kIOReturnSuccess {
                assertionID = newAssertionID
            }
        } else if !shouldHold, let assertionID {
            IOPMAssertionRelease(assertionID)
            self.assertionID = nil
        }
    }
}
