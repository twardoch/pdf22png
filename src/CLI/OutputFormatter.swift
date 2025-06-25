import Foundation

// MARK: - Output Formatter

struct OutputFormatter {
    static func printHelp() {
        print("""
Usage: pdf22png [OPTIONS] <input.pdf> [output.png]
Converts PDF documents to PNG images.

Options:
  -p, --page <spec>       Page(s) to convert. Single page, range, or comma-separated.
                          Examples: 1 | 1-5 | 1,3,5-10 (default: 1)
                          In batch mode, only specified pages are converted.
  -a, --all               Convert all pages. If -d is not given, uses input filename as prefix.
                          Output files named <prefix>-<page_num>.png.
  -r, --resolution <dpi>  Set output DPI (e.g., 150dpi). Overrides -s if both used with numbers.
  -s, --scale <spec>      Scaling specification (default: 100% or 1.0).
                            NNN%: percentage (e.g., 150%)
                            N.N:  scale factor (e.g., 1.5)
                            WxH:  fit to WxH pixels (e.g., 800x600)
                            Wx:   fit to width W pixels (e.g., 1024x)
                            xH:   fit to height H pixels (e.g., x768)
  -t, --transparent       Preserve transparency (default: white background).
  -q, --quality <n>       PNG compression quality (0-9, default: 6). Currently informational.
  -o, --output <path>     Output PNG file or prefix for batch mode.
                          If '-', output to stdout (single page mode only).
  -d, --directory <dir>   Output directory for batch mode (converts all pages).
                          If used, -o specifies filename prefix inside this directory.
  -v, --verbose           Verbose output.
  -n, --name              Include extracted text in output filename (batch mode only).
  -P, --pattern <pat>     Custom naming pattern for batch mode. Placeholders:
                          {basename} - Input filename without extension
                          {page} - Page number (auto-padded)
                          {page:03d} - Page with custom padding
                          {text} - Extracted text (requires -n)
                          {date} - Current date (YYYYMMDD)
                          {time} - Current time (HHMMSS)
                          {total} - Total page count
                          Example: '{basename}_p{page:04d}_of_{total}'
  -D, --dry-run           Preview operations without writing files.
  -f, --force             Force overwrite existing files without prompting.
  -h, --help              Show this help message and exit.
  --version               Show version information and exit.

Arguments:
  <input.pdf>             Input PDF file. If '-', reads from stdin.
  [output.png]            Output PNG file. Required if not using -o or -d.
                          If input is stdin and output is not specified, output goes to stdout.
                          In batch mode (-a or -d), this is used as a prefix if -o is not set.

Examples:
  pdf22png document.pdf page1.png              # Convert first page
  pdf22png -p 5 document.pdf page5.png         # Convert page 5
  pdf22png -a document.pdf                     # Convert all pages (document-001.png, ...)
  pdf22png -r 300 document.pdf hi-res.png      # High resolution
  pdf22png -s 150% document.pdf large.png      # 1.5x scale
  pdf22png -d output/ document.pdf             # All pages to output/ directory
  pdf22png -t document.pdf transparent.png     # Preserve transparency
  cat document.pdf | pdf22png - output.png     # From stdin
""")
    }
    
    static func printVersion() {
        let version = "2.0.0-standalone"
        print("pdf22png \(version)")
        print("Swift standalone implementation")
    }
    
    static func formatError(_ error: PDF22PNGError, context: String? = nil) -> String {
        var output = "❌ Error: \(error.errorDescription ?? "Unknown error")"
        
        if let ctx = context {
            output += "\n📍 Context: \(ctx)"
        }
        
        if let suggestion = error.recoverySuggestion {
            output += "\n💡 Help: \(suggestion)"
        }
        
        return output
    }
    
    static func formatProgress(_ progress: ProgressInfo) -> String {
        let percentage = Int((Double(progress.completed) / Double(progress.total)) * 100)
        let progressBar = createProgressBar(percentage: percentage)
        
        var output = "\r\(progressBar) \(percentage)% (\(progress.completed)/\(progress.total))"
        
        if let speed = progress.speed {
            output += " - \(String(format: "%.1f", speed)) pages/sec"
        }
        
        if let eta = progress.estimatedTimeRemaining {
            output += " - ETA: \(formatDuration(eta))"
        }
        
        return output
    }
    
    static func formatResults(_ results: ProcessingResults) -> String {
        var output = "\n✅ Processing complete!\n"
        output += "   Total: \(results.totalPages) pages"
        
        if results.processingTime > 0 {
            output += " in \(formatDuration(results.processingTime))"
        }
        
        output += "\n   Results: ✓ \(results.successfulPages) successful"
        
        if results.failedPages > 0 {
            output += ", ✗ \(results.failedPages) failed"
        }
        
        if results.pagesPerSecond > 0 {
            output += "\n   Average speed: \(String(format: "%.1f", results.pagesPerSecond)) pages/sec"
        }
        
        return output
    }
    
    private static func createProgressBar(percentage: Int, width: Int = 20) -> String {
        let filled = Int(Double(percentage) / 100.0 * Double(width))
        let empty = width - filled
        return "[" + String(repeating: "█", count: filled) + String(repeating: "░", count: empty) + "]"
    }
    
    private static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Progress Info

struct ProgressInfo {
    let completed: Int
    let total: Int
    let speed: Double?
    let estimatedTimeRemaining: TimeInterval?
    let currentOperation: String?
}