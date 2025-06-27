class Pdf21png < Formula
  desc "High-performance PDF to PNG converter for macOS (Objective-C implementation)"
  homepage "https://github.com/twardoch/pdf22png"
  url "https://github.com/twardoch/pdf22png/archive/refs/tags/v2.1.0.tar.gz" # Placeholder, update with actual release tag
  sha256 "YOUR_PDF21PNG_SHA256_HERE" # Placeholder, update with actual SHA256
  license "MIT"
  head "https://github.com/twardoch/pdf22png.git", branch: "main"

  depends_on :macos

  def install
    # Build pdf21png (Objective-C) from its directory
    cd "pdf21png" do
      system "make", "install", "PREFIX=#{prefix}"
    end
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

    system "#{bin}/pdf21png", "test.pdf", "output.png"
    assert_predicate testpath/"output.png", :exist?
  end
end
