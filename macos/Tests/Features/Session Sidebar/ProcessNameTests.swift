import Testing
@testable import Ghostty

struct ProcessNameTests {
    @Test func basenameOfCurrentProcess() {
        let name = ProcessName.basename(pid: ProcessInfo.processInfo.processIdentifier)
        #expect(name?.isEmpty == false)
    }

    @Test func deadPidIsNil() {
        #expect(ProcessName.basename(pid: -1) == nil)
    }
}
