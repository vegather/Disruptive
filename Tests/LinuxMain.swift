import XCTest

import DisruptiveTests

var tests = [XCTestCaseEntry]()
tests += DisruptiveTests.allTests()
XCTMain(tests)
