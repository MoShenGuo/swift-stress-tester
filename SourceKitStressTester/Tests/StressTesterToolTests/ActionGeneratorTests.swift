//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest
@testable import StressTester
import SwiftLang
import Common

class ActionGeneratorTests: XCTestCase {
  var workspace: URL!
  var testFile: URL!
  var testFileContent: String!

  func testRequestActionGenerator() {
    let actions = RequestActionGenerator().generate(for: testFile)
    verify(actions, rewriteMode: .none)
  }

  func testRewriteActionGenerator() {
    let actions = RewriteActionGenerator().generate(for: testFile)
    verify(actions, rewriteMode: .basic)
  }

  func testConcurrentRewriteActionGenerator() {
    let actions = ConcurrentRewriteActionGenerator().generate(for: testFile)
    verify(actions, rewriteMode: .concurrent)
  }

  func testInsideOutActionGenerator() {
    let actions = InsideOutRewriteActionGenerator().generate(for: testFile)
    verify(actions, rewriteMode: .insideOut)
  }

  func verify(_ actions: [Action], rewriteMode: RewriteMode) {
    var state = SourceState(rewriteMode: rewriteMode, content: testFileContent)

    for action in actions {
      let eof = state.source.utf8.count
      switch action {
      case .cursorInfo(let offset):
        XCTAssertTrue(offset >= 0 && offset <= eof)
      case .codeComplete(let offset):
        XCTAssertTrue(offset >= 0 && offset <= eof)
      case .rangeInfo(let offset, let length):
        XCTAssertTrue(offset >= 0 && offset <= eof)
        XCTAssertTrue(length >= 0 && offset + length <= eof)
      case .replaceText(let offset, let length, let text):
        XCTAssertTrue(offset >= 0 && offset <= eof)
        XCTAssertTrue(length >= 0 && offset + length <= eof)
        state.replace(offset: offset, length: length, with: text)
      }
    }
    XCTAssertEqual(state.source, testFileContent)
  }

  override func setUp() {
    super.setUp()

    workspace = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("ActionGeneratorTests", isDirectory: true)

    try? FileManager.default.removeItem(at: workspace)
    try! FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: false)

    testFile = workspace
      .appendingPathComponent("test.swift", isDirectory: false)

    testFileContent = """
      func minMax(array: [Int]) -> (min: Int, max: Int) {
          var currentMin = array[0]
          var currentMax = array[0]
          for value in array[1..<array.count] {
              if value < currentMin {
                  currentMin = value
              } else if value > currentMax {
                  currentMax = value
              }
          }
          return (currentMin, currentMax)
      }

      let result = minMax(array: [10, 43, 1, 2018])
      print("range: \\(result.min) – \\(result.max)")
      """

    FileManager.default.createFile(atPath: testFile.path, contents: testFileContent.data(using: .utf8))
  }
}
