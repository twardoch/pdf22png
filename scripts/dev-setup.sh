#!/bin/bash

# PDF22PNG Development Environment Setup
# Sets up the development environment for contributors

set -e

echo "🚀 Setting up pdf22png development environment..."
echo ""

# Check if we're in the right directory
if [ ! -f "CLAUDE.md" ] || [ ! -f "src/main.swift" ]; then
    echo "❌ Error: Please run this script from the pdf22png project root directory"
    exit 1
fi

# Check Swift installation
echo "📋 Checking Swift installation..."
if ! command -v swift &> /dev/null; then
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
if command -v swiftlint &> /dev/null; then
    SWIFTLINT_VERSION=$(swiftlint version)
    echo "✅ SwiftLint: $SWIFTLINT_VERSION"
else
    echo "⚠️  SwiftLint not found. Install with: brew install swiftlint"
    echo "   (Optional but recommended for code quality)"
fi

# swift-format
if command -v swift-format &> /dev/null; then
    echo "✅ swift-format: Available"
else
    echo "⚠️  swift-format not found. Install with: brew install swift-format"
    echo "   (Optional but recommended for code formatting)"
fi

# Test the build system
echo ""
echo "🧹 Cleaning previous builds..."
make clean > /dev/null 2>&1
echo "✅ Clean complete"

echo "🔨 Testing build..."
if make quick-build; then
    echo "✅ Build system working"
else
    echo "❌ Build failed - please check errors above"
    exit 1
fi

# Run tests
echo ""
echo "🧪 Running tests..."
if make test > /dev/null 2>&1; then
    echo "✅ Tests passing"
else
    echo "❌ Tests failed"
    exit 1
fi

# Format code if swift-format is available
if command -v swift-format &> /dev/null; then
    echo ""
    echo "🎨 Formatting code..."
    make format > /dev/null 2>&1
    echo "✅ Code formatted"
fi

# Run linting if SwiftLint is available
if command -v swiftlint &> /dev/null; then
    echo ""
    echo "🔍 Running code analysis..."
    make lint
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