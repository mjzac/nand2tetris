import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(hack_assemblerTests.allTests),
    ]
}
#endif
