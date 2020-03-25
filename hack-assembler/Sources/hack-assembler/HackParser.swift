//
//  HackParser.swift
//  hack-assembler
//
//  Created by Melson Zacharias on 25/03/20.
//

import Foundation

struct ParserProvider {
    private static let parser: HackParser = HackParser()
    static func getParser() -> HackParser {
        return parser
    }
}
fileprivate struct AInstruction {
    let symbolTable: SymbolTable
    let plainInstruction: String
    let instructionAddress: Int

    private func getMachineCode(address: Int) -> String {
        let binaryString = String(address, radix: 2)
        return binaryString.pad(toSize: 16)
    }
    func execute() -> String {
        var address: Int
        let selectionItem = String(plainInstruction.dropFirst())
        let isVariable = !selectionItem.isNumeric

        // Add variable to symbol table if it doesn't exist
        if isVariable && symbolTable.get(key: selectionItem) == nil {
            symbolTable.add(key: selectionItem)
            address = symbolTable.get(key: selectionItem) ?? 0
        } else if let addr = symbolTable.get(key: selectionItem) {
            address = addr
        } else {
            address = Int(selectionItem)!
        }

        return getMachineCode(address: address)
    }
}
fileprivate func hydrateOps() -> [String: String] {
    // x -> A or M
    return [
        "0": "101010",
        "1": "111111",
        "-1": "111010",
        "D": "001100",
        "x": "110000",
        "!D": "001101",
        "!x": "110001",
        "-D": "001111",
        "-x": "110011",
        "D+1": "011111",
        "x+1": "110111",
        "D-1": "001110",
        "x-1": "110010",
        "D+x": "000010",
        "D-x": "010011",
        "x-D": "000111",
        "D&x": "000000",
        "D|x": "010101",
    ]
}

fileprivate func hydrateDestLookup() -> [String: String] {
    return [
        "null": "000",
        "M": "001",
        "D": "010",
        "MD": "011",
        "A": "100",
        "AM": "101",
        "AD": "110",
        "AMD": "111"
    ]
}
fileprivate func hydrateJumpLookup() -> [String: String] {
    return [
        "null": "000",
        "JGT": "001",
        "JEQ": "010",
        "JGE": "011",
        "JLT": "100",
        "JNE": "101",
        "JLE": "110",
        "JMP": "111"
    ]
}
fileprivate struct CInstruction {
    let symbolTable: SymbolTable
    let plainInstruction: String
    let instructionAddress: Int
    let opLookup = hydrateOps()
    let destLookup = hydrateDestLookup()
    let jumpLookup = hydrateJumpLookup()

    private func getMachineCode() -> String {
        var assignee = "null"
        var opIdxStart = plainInstruction.startIndex;

        if let assignment = plainInstruction.firstIndex(of: "=") {
            assignee = String(plainInstruction.prefix(upTo: assignment))
            opIdxStart = plainInstruction.index(after: assignment)
        }
        var jump = "null"
        var opIdxStop = plainInstruction.endIndex
        if let jumping = plainInstruction.firstIndex(of: ";") {
            jump = String(plainInstruction.suffix(from: plainInstruction.index(after: jumping)))
            opIdxStop = jumping
        }
        let extractedOp = plainInstruction[opIdxStart..<opIdxStop]
        let op = extractedOp
            .replacingOccurrences(of: "M", with: "x")
            .replacingOccurrences(of: "A", with: "x")

        let aValue = extractedOp.contains("M") ? 1 : 0
        let opcode = opLookup[op] ?? ""
        let dest = destLookup[assignee] ?? ""
        let jmp = jumpLookup[jump] ?? ""
        
        return "111\(aValue)\(opcode)\(dest)\(jmp)"
    }
    func execute() -> String {
        return getMachineCode()
    }
}
fileprivate enum Instruction {
    case aInstruction(AInstruction)
    case cInstruction(CInstruction)
    case labelInstruction(String)
    case comment
}
fileprivate class SymbolTable {
    private var lookup: [String: Int] = [:]
    private let variableAllocationStartAddress = 16
    private var variableCount = 0
    init() {
        // Bootstrap with predefined symbolTable
        for i in 0...15 {
            lookup["R\(i)"] = i
        }
        lookup["SCREEN"] = 16384
        lookup["KBD"] = 24576
        lookup["SP"] = 0
        lookup["LCL"] = 1
        lookup["ARG"] = 2
        lookup["THIS"] = 3
        lookup["THAT"] = 4
    }
    func add(key: String) {
        lookup[key] = variableAllocationStartAddress + variableCount
        variableCount += 1
    }
    func add(key: String, value: Int) {
        lookup[key] = value
    }
    func get(key: String) -> Int? {
        return lookup[key]
    }
    var description: [String: Int] {
        get {
            return lookup
        }
    }
}
struct HackParser {
    private var needAnotherPass: Bool = false
    private let symbolTable = SymbolTable()
    private var instructionSet: [Instruction] = []
    private var instructionCounter = 0
    private var machineCode: [String] = []

    // Disallow direct instantiation outside this file.
    fileprivate init() {
        
    }
    private mutating func parseInstructionType(instruction: String) -> Instruction {
        var parsedInstruction: Instruction

        let firstChar = instruction.first
        switch firstChar {
        case "@":
            parsedInstruction = .aInstruction(AInstruction(symbolTable: symbolTable, plainInstruction: instruction, instructionAddress: instructionCounter))
            instructionCounter += 1
        case "(":
            parsedInstruction = .labelInstruction(instruction)
            let label = instruction.dropFirst().dropLast()
            symbolTable.add(key: String(label), value: instructionCounter)

        default:
            parsedInstruction = .cInstruction(CInstruction(symbolTable: symbolTable, plainInstruction: instruction, instructionAddress: instructionCounter))
            instructionCounter += 1
        }
        return parsedInstruction
    }

    mutating func parse(instruction: String) {
        var theInstruction = instruction
        theInstruction.removeComments()
        theInstruction = theInstruction.removeWhiteSpaces()
        if theInstruction.isEmpty  {
            return
        }
        instructionSet.append(parseInstructionType(instruction: theInstruction))
    }

    mutating func execute() -> String {
        for instruction in instructionSet {
            switch instruction {
            case .aInstruction(let aInstruction):
                machineCode.append(aInstruction.execute())
            case .cInstruction(let cInstruction):
                machineCode.append(cInstruction.execute())
            default:
                continue

            }
        }
        return machineCode.joined(separator: "\n")
    }


}

fileprivate extension String {
    func pad(toSize: Int) -> String {
      var padded = self
      for _ in 0..<(toSize - self.count) {
        padded = "0" + padded
      }
        return padded
    }
    mutating func removeComments() {
        if let idx = self.range(of: "//") {
            let commentRange = Range(uncheckedBounds: (idx.lowerBound, self.endIndex))
            self.removeSubrange(commentRange)
        }
    }
    mutating func removeWhiteSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    var isNumeric : Bool {
           return NumberFormatter().number(from: self) != nil
    }
}
