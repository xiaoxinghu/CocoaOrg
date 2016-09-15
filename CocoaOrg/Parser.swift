//
//  Parser.swift
//  CocoaOrg
//
//  Created by Xiaoxing Hu on 22/08/16.
//  Copyright © 2016 Xiaoxing Hu. All rights reserved.
//

import Foundation

public enum Errors: Error {
    case unexpectedToken(String)
}

open class Parser {
    // MARK: properties
    var tokens: Queue<Token>
    
    // MARK: init
    public init(tokens: [Token]) {
        self.tokens = Queue<Token>(data: tokens)
    }
    
    public convenience init(lines: [String]) throws {
        let lexer = Lexer(lines: lines)
        self.init(tokens: try lexer.tokenize())
    }
    
    public convenience init(content: String) throws {
        try self.init(lines: content.lines)
    }
    
    // MARK: Greater Elements
    func parseBlock() throws -> Node {
        guard case let Token.blockBegin(meta, type, params) = tokens.dequeue()! else {
            throw Errors.unexpectedToken("BlockBegin expected")
        }
        var block = Block(type: type, params: params)
        tokens.takeSnapshot()
        while let token = tokens.dequeue() {
            switch token {
            case let .blockEnd(_, t):
                if t.lowercased() != type.lowercased() {
                    throw Errors.unexpectedToken("Expecting BlockEnd of type \(type), but got \(t)")
                }
                return block
            default:
                block.content.append(token.meta.raw ?? "")
            }
        }
        tokens.restore()
        return try self.parseLines(meta.raw?.trimmed)
    }
    
    func parseList() throws -> List {
        guard case let Token.listItem(_, indent, text, ordered) = tokens.dequeue()! else {
            throw Errors.unexpectedToken("ListItem expected")
        }
        var list = List(ordered: ordered)
        list.items = [ListItem(text: text)]
        while let token = tokens.peek() {
            if case let .listItem(_, i, t, _) = token {
                if i > indent {
                    var lastItem = list.items.removeLast()
                    lastItem.list = try parseList()
                    list.items += [lastItem]
                } else if i == indent {
                    _ = tokens.dequeue()
                    list.items += [ListItem(text: t)]
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return list
    }
    
    func parseLines(_ startWith: String? = nil) throws -> Paragraph {
        guard case Token.line(_, let text) = tokens.dequeue()! else {
            throw Errors.unexpectedToken("Line expected")
        }
        var line = Paragraph(lines: [text])
        if let firstLine = startWith {
            line.lines.insert(firstLine, at: 0)
        }
        while let token = tokens.peek() {
            if case .line(_, let t) = token {
                line.lines.append(t)
                _ = tokens.dequeue()
            } else {
                break
            }
        }
        return line
    }
    
    
    func parseSection(_ parent: OrgNode) throws {
        while let token = tokens.peek() {
            switch token {
            case let .header(_, l, t):
                if l <= getCurrentLevel(parent) {
                    return
                }
                _ = tokens.dequeue()
                let subSection = parent.add(Section(
                    level: l, title: t, todos: getTodos(parent)))
                try parseSection(subSection)
            case .blank:
                _ = tokens.dequeue()
                _ = parent.add(Blank())
            case .line:
                _ = parent.add(try parseLines())
            case let .comment(_, t):
                _ = tokens.dequeue()
                _ = parent.add(Comment(text: t))
            case .blockBegin:
                _ = parent.add(try parseBlock())
            case .listItem:
                _ = parent.add(try parseList())
            default:
                throw Errors.unexpectedToken("\(token) is not expected")
            }
        }
    }
    
    func parseDocument() throws -> OrgNode {
        let document = OrgNode(value: DocumentMeta())
        
        while let token = tokens.peek() {
            switch token {
            case let .setting(_, key, value):
                _ = tokens.dequeue()
                if var meta = document.value as? DocumentMeta {
                    meta.settings[key] = value
                    document.value = meta
                }
            //                doc.settings[key] = value
            default:
                try parseSection(document)
            }
        }
        //        document.value = doc
        return document
    }
    
    // MARK: helpers
    func getCurrentLevel(_ node: OrgNode) -> Int {
        if let section = node.value as? Section {
            return section.level
        }
        if let p = node.parent {
            return getCurrentLevel(p)
        }
        return 0
    }
    
    func getTodos(_ node: OrgNode) -> [String] {
        if let doc = node.lookUp(DocumentMeta.self) {
            return doc.todos
        }
        // TODO make it robust
        print("+++ Cannot find DocumentMeta")
        return []
    }
    
    
    open func parse() throws -> OrgNode {
        return try parseDocument()
    }
}
