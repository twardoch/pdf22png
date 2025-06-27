class Pdf22png < Formula
  desc "Modern PDF to PNG converter with advanced features (Swift implementation)"
  homepage "https://github.com/twardoch/pdf22png"
  version "2.2.0"
  
  # NOTE: Update these values when creating a release:
  # 1. Replace URL with: https://github.com/twardoch/pdf22png/releases/download/v2.2.0/pdf22png-v2.2.0-macos-universal.tar.gz
  # 2. Replace SHA256 with actual checksum from release
  url "https://github.com/twardoch/pdf22png/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_UPDATE_ON_RELEASE"
  
  license "MIT"
  head "https://github.com/twardoch/pdf22png.git", branch: "main"

  depends_on :macos => :big_sur # macOS 11.0+
  depends_on xcode: ["12.5", :build] if build.head?

  def install
    if build.head?
      # Build from source for HEAD installations
      cd "pdf22png" do
        system "swift", "build", 
               "--disable-sandbox",
               "-c", "release",
               "--arch", "arm64",
               "--arch", "x86_64"
      end
      bin.install "pdf22png/.build/apple/Products/Release/pdf22png"
    else
      # Install pre-built binary from release
      bin.install "pdf22png"
    end
    
    # Install man page if available
    man1.install "docs/pdf22png.1" if File.exist?("docs/pdf22png.1")
  end

  def caveats
    <<~EOS
      pdf22png is the modern Swift implementation with advanced features.
      
      For the high-performance Objective-C version, install pdf21png:
        brew install pdf21png
        
      This is the recommended version for most users, offering:
      • Better command-line interface
      • Extended scaling options
      • Active development
      
      Note: If you used 'pdf22png' before v2.0, the command now uses 
      the Swift implementation. For the original, use 'pdf21png'.
    EOS
  end

  test do
    # Create a simple test PDF
    (testpath/"test.pdf").write <<~EOS
      %PDF-1.4
      1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
      2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
      3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >> endobj
      xref
      0 4
      0000000000 65535 f
      0000000009 00000 n
      0000000058 00000 n
      0000000115 00000 n
      trailer << /Size 4 /Root 1 0 R >>
      startxref
      190
      %%EOF
    EOS

    # Test basic conversion
    system "#{bin}/pdf22png", "test.pdf", "output.png"
    assert_predicate testpath/"output.png", :exist?
    
    # Test with options
    system "#{bin}/pdf22png", "--resolution", "150", "test.pdf", "output2.png"
    assert_predicate testpath/"output2.png", :exist?
    
    # Test help
    assert_match "USAGE:", shell_output("#{bin}/pdf22png --help 2>&1")
    
    # Test version
    assert_match "2.2", shell_output("#{bin}/pdf22png --version 2>&1")
  end
end