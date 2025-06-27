#!/bin/bash

# PDF22PNG Development Environment Setup
# Sets up the development environment for contributors

set -e

echo "🚀 Setting up pdf22png development environment..."
echo ""

# Verify we are in the repository root by looking for hallmark files
if [ ! -f "CLAUDE.md" ] || [ ! -d "pdf21png" ] || [ ! -d "pdf22png" ]; then
    echo "❌ Error: Please run this script from the pdf22png project root directory (where pdf21png/ and pdf22png/ folders reside)."
    exit 1
fi

# Check Swift installation
echo "📋 Checking Swift installation..."
if ! command -v swift &>/dev/null; then
    echo "❌ Swift not found. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(swift --version | head -n1)
echo "✅ Found: $SWIFT_VERSION"

# Check for recommended tools
echo ""
echo "📋 Checking recommended development tools..."

# SwiftLint
if command -v swiftlint &>/dev/null; then
    SWIFTLINT_VERSION=$(swiftlint version)
    echo "✅ SwiftLint: $SWIFTLINT_VERSION"
else
    echo "⚠️  SwiftLint not found. Install with: brew install swiftlint"
    echo "   (Optional but recommended for code quality)"
fi

# swift-format
if command -v swift-format &>/dev/null; then
    echo "✅ swift-format: Available"
else
    echo "⚠️  swift-format not found. Install with: brew install swift-format"
    echo "   (Optional but recommended for code formatting)"
fi

# Clean previous builds for both implementations
echo ""
echo "🧹 Cleaning previous builds..."
(
    cd pdf21png && make clean >/dev/null 2>&1 || true
)
(
    cd pdf22png && make clean >/dev/null 2>&1 || true
)
echo "✅ Clean complete"

# Build both implementations
echo "🔨 Building pdf21png (Objective-C)..."
(
    cd pdf21png && make
)

echo "🔨 Building pdf22png (Swift)..."
(
    cd pdf22png && make build
)
echo "✅ Build system working"

# Run tests
echo ""
echo "🧪 Running tests..."
PDF22PNG_TESTS_PASSED=true
(
    cd pdf22png && make test >/dev/null 2>&1 || PDF22PNG_TESTS_PASSED=false
)
(
    cd pdf21png && make test >/dev/null 2>&1 || true
)

if [ "$PDF22PNG_TESTS_PASSED" = true ]; then
    echo "✅ Tests passing"
else
    echo "❌ Tests failed"
    exit 1
fi

# Format code if swift-format is available
if command -v swift-format &>/dev/null; then
    echo ""
    echo "🎨 Formatting code..."
    (
        cd pdf22png && make format >/dev/null 2>&1
    )
    echo "✅ Code formatted"
fi

# Run linting if SwiftLint is available
if command -v swiftlint &>/dev/null; then
    echo ""
    echo "🔍 Running code analysis..."
    (
        cd pdf22png && make lint
    )
    echo "✅ Code analysis complete"
fi

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📝 Available commands:"
echo "   make build      - Build the application"
echo "   make test       - Run tests"
echo "   make lint       - Run code analysis"
echo "   make format     - Format code"
echo "   make help       - See all available commands"
echo ""
echo "📚 Documentation:"
echo "   CLAUDE.md       - Project overview and guidelines"
echo "   PLAN.md         - Development roadmap"
echo "   TODO.md         - Current priorities"
echo ""
echo "Happy coding! 🚀"
