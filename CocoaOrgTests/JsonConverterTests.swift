//
//  JsonConverterTests.swift
//  CocoaOrg
//
//  Created by Xiaoxing Hu on 21/09/16.
//  Copyright © 2016 Xiaoxing Hu. All rights reserved.
//

import XCTest
import CocoaOrg

class JsonConverterTests: XCTestCase {
    
    var content: String = ""
    override func setUp() {
        super.setUp()
        do {
            let path = Bundle(for: type(of: self)).path(forResource: "test", ofType: "org")
            content = try String(contentsOfFile: path!)
        } catch {
            XCTFail("ERROR: \(error)")
        }
    }
    
    func testConverter() throws {
        let parser = OrgParser()
        let json = try parser.parse(content: content).toJson(options: .prettyPrinted)
        print(json)
    }
    
}
