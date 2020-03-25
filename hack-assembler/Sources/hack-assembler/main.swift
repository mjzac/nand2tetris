import ArgumentParser

struct HackAssemblerCLI: ParsableCommand {
    @Argument(help: "Absolute path to the .asm file")
    var filename: String

    @Option(name: .shortAndLong, help: "Name of output file")
    var outputFileName: String?

    func run() throws {
        var parser = ParserProvider.getParser()
        print("Reading \(filename): \n")
        let reader = try FileReader(filepath: filename)
        for line in reader {
            parser.parse(instruction: line)
        }
        let generatedCode = parser.execute()
        if let outputFile = outputFileName {
            try generatedCode.write(toFile: outputFile, atomically: true, encoding: .utf8)
            print("Wrote to file \(outputFile)")

        } else {
            print(generatedCode)
        }
        
    }
}

HackAssemblerCLI.main()
