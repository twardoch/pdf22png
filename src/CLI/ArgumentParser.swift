import Foundation

// MARK: - Command Line Argument Parser

struct ArgumentParser {
    static func parseArguments() -> ProcessingOptions {
        var options = ProcessingOptions()
        let args = Array(CommandLine.arguments.dropFirst())
        var i = 0
        
        while i < args.count {
            let arg = args[i]
            
            switch arg {
            case "-h", "--help":
                options.showHelp = true
                return options
                
            case "--version":
                options.showVersion = true
                return options
                
            case "-p", "--page":
                guard i + 1 < args.count else {
                    print("Error: --page requires a value")
                    exit(2)
                }
                options.page = args[i + 1]
                i += 1
                
            case "-a", "--all":
                options.allPages = true
                
            case "-r", "--resolution":
                guard i + 1 < args.count else {
                    print("Error: --resolution requires a value")
                    exit(2)
                }
                options.resolution = args[i + 1]
                i += 1
                
            case "-s", "--scale":
                guard i + 1 < args.count else {
                    print("Error: --scale requires a value")
                    exit(2)
                }
                options.scale = args[i + 1]
                i += 1
                
            case "-t", "--transparent":
                options.transparent = true
                
            case "-q", "--quality":
                guard i + 1 < args.count else {
                    print("Error: --quality requires a value")
                    exit(2)
                }
                guard let quality = Int(args[i + 1]), quality >= 0 && quality <= 9 else {
                    print("Error: quality must be between 0 and 9")
                    exit(2)
                }
                options.quality = quality
                i += 1
                
            case "-o", "--output":
                guard i + 1 < args.count else {
                    print("Error: --output requires a value")
                    exit(2)
                }
                options.outputPath = args[i + 1]
                i += 1
                
            case "-d", "--directory":
                guard i + 1 < args.count else {
                    print("Error: --directory requires a value")
                    exit(2)
                }
                options.directory = args[i + 1]
                i += 1
                
            case "-v", "--verbose":
                options.verbose = true
                
            case "-n", "--name":
                options.includeText = true
                
            case "-P", "--pattern":
                guard i + 1 < args.count else {
                    print("Error: --pattern requires a value")
                    exit(2)
                }
                options.namingPattern = args[i + 1]
                i += 1
                
            case "-D", "--dry-run":
                options.dryRun = true
                
            case "-f", "--force":
                options.forceOverwrite = true
                
            default:
                if arg.hasPrefix("-") {
                    print("Error: Unknown option: \(arg)")
                    print("Use --help for usage information")
                    exit(2)
                } else {
                    // Positional arguments
                    if options.inputFile == nil {
                        options.inputFile = arg
                    } else if options.outputFile == nil {
                        options.outputFile = arg
                    } else {
                        print("Error: Too many arguments")
                        exit(2)
                    }
                }
            }
            i += 1
        }
        
        return options
    }
    
    static func validateArguments(_ options: ProcessingOptions) throws {
        // Input validation
        if options.inputFile == nil && !options.isStdinMode {
            throw PDF22PNGError.noInput
        }
        
        // Output validation for single page mode
        if !options.isBatchMode && options.outputFile == nil && options.outputPath == nil {
            throw PDF22PNGError.invalidArgs
        }
        
        // Scale validation
        if ScaleParser.parseScaleSpecification(options.effectiveScale) == nil {
            throw PDF22PNGError.invalidScale
        }
        
        // Quality validation (already handled in parsing)
        if options.quality < 0 || options.quality > 9 {
            throw PDF22PNGError.invalidArgs
        }
    }
}