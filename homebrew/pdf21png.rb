class Pdf21png < Formula
  desc "High-performance PDF to PNG converter for macOS (Objective-C implementation)"
  homepage "https://github.com/twardoch/pdf22png"
  version "2.1.0"
  
  # NOTE: Update these values when creating a release:
  # 1. Replace URL with: https://github.com/twardoch/pdf22png/releases/download/v2.1.0/pdf21png-v2.1.0-macos-universal.tar.gz
  # 2. Replace SHA256 with actual checksum from release
  url "https://github.com/twardoch/pdf22png/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_UPDATE_ON_RELEASE"
  
  license "MIT"
  head "https://github.com/twardoch/pdf22png.git", branch: "main"

  depends_on :macos => :catalina # macOS 10.15+

  def install
    if build.head?
      # Build from source for HEAD installations
      cd "pdf21png" do
        system "make", "clean"
        system "make", "universal"
      end
      bin.install "pdf21png/build/pdf21png"
    else
      # Install pre-built binary from release
      bin.install "pdf21png"
    end
    
    # Install man page if available
    man1.install "docs/pdf21png.1" if File.exist?("docs/pdf21png.1")
  end

  def caveats
    <<~EOS
      pdf21png is the high-performance Objective-C implementation.
      
      For the modern Swift version with additional features, install pdf22png:
        brew install pdf22png
        
      If you previously used 'pdf22png' command, it now refers to the Swift version.
      This tool (pdf21png) is the original Objective-C implementation.
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
    system "#{bin}/pdf21png", "test.pdf", "output.png"
    assert_predicate testpath/"output.png", :exist?
    
    # Test help flag
    assert_match "Usage:", shell_output("#{bin}/pdf21png --help 2>&1", 1)
    
    # Test version flag
    assert_match "2.1", shell_output("#{bin}/pdf21png --version 2>&1")
  end
end
