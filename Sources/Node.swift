//
//  Nodes.swift
//  SwiftOrg
//
//  Created by Xiaoxing Hu on 22/08/16.
//  Copyright © 2016 Xiaoxing Hu. All rights reserved.
//

import Foundation

/// Index of elements within org file.
public struct OrgIndex: CustomStringConvertible, Hashable {
  var indexes: [Int]
  
  public init(_ theIndexes: [Int] = []) {
    indexes = theIndexes
  }
  
  public var out: OrgIndex {
    var newIndex = indexes
    newIndex.removeLast()
    return OrgIndex(newIndex)
  }
  
  public var `in`: OrgIndex {
    var newIndex = indexes
    newIndex.append(0)
    return OrgIndex(newIndex)
  }
  
  public var next: OrgIndex {
    var newIndex = indexes
    newIndex[newIndex.endIndex - 1] = newIndex.last! + 1
    return OrgIndex(newIndex)
  }
  
  public var prev: OrgIndex {
    var newIndex = indexes
    newIndex[newIndex.endIndex - 1] = newIndex.last! - 1
    return OrgIndex(newIndex)
  }
  
  public var description: String {
    return indexes.map { n in
      return "\(n)"
      }.joined(separator: ".")
  }
  
  public var hashValue: Int {
    return description.hashValue
  }
  
  public static func == (lhs: OrgIndex, rhs: OrgIndex) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}

public protocol Node: CustomStringConvertible {
  var index: OrgIndex? { get }
}

extension Node {
  public var index: OrgIndex? { return nil }
}

protocol NodeContainer: Node {
  var content: [Node] { get set }
}
