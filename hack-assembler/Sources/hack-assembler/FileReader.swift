//
//  FileReader.swift
//  hack-assembler
//
//  Created by Melson Zacharias on 25/03/20.
//

import Foundation

struct FileReader: Sequence {
    private let sourceCode: [String]

    init(filepath: String) throws {
        sourceCode = try String(contentsOfFile: filepath)
                        .replacingOccurrences(of: "\r", with: "")
                        .split(separator: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    func count() -> Int {
        return sourceCode.count
    }

    func makeIterator() -> FileReaderIterator {
        return FileReaderIterator(reader: self)
    }
    func get(position: Int) -> String {
        return sourceCode[position]
    }
}

struct FileReaderIterator: IteratorProtocol {
    typealias Element = String

    let reader: FileReader
    var i = 0

    init(reader fReader: FileReader) {
        reader = fReader
    }
    mutating func next() -> String? {
        let nextNumber =  i
        guard nextNumber < reader.count() else {
            return nil
        }
        i += 1
        return reader.get(position: nextNumber)
    }
}
