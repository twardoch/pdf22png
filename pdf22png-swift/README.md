# PDF22PNG - Swift Implementation

Modern Swift implementation of the PDF to PNG converter with advanced features and type safety.

## Features

- **Modern Swift**: Built with Swift 5.7+ and Swift Package Manager
- **Type Safety**: Comprehensive error handling with Swift enums
- **Modular Architecture**: Clean separation of concerns
- **Advanced Features**:
  - Memory management and pressure monitoring
  - Async batch processing
  - Signal handling for graceful shutdown
  - Input validation and sanitization
  - Progress reporting with statistics
  - Resource management

## Building

```bash
make                    # Build release version
make debug             # Build debug version
swift build -c release # Direct Swift build
```

## Testing

```bash
make test              # Run test suite
swift test             # Direct Swift test
```

## Installation

```bash
make install           # Install to /usr/local/bin/pdf22png-swift
make uninstall         # Remove installation
```

## Usage

The Swift implementation provides the same CLI interface as the Objective-C version:

```bash
# Convert single page
./build/release/pdf22png-swift input.pdf output.png

# Convert with memory monitoring
./build/release/pdf22png-swift -v -a large-document.pdf

# Batch processing with progress
./build/release/pdf22png-swift -a -d output/ document.pdf
```

## Architecture

### Core Modules

- **Core/**: Core processing logic (BatchProcessor, ImageRenderer, etc.)
- **Models/**: Data structures and error definitions
- **Utilities/**: Input validation and progress reporting
- **CLI/**: Command-line interface and argument parsing

### Key Components

- **MemoryManager**: Monitors system memory and prevents OOM
- **SignalHandler**: Graceful shutdown on interrupts
- **BatchProcessor**: Async parallel processing with progress tracking
- **InputValidator**: Comprehensive input validation and sanitization

## Implementation Details

- **Language**: Swift 5.7+
- **Frameworks**: Foundation, CoreGraphics, ArgumentParser
- **Architecture**: Modular with dependency injection
- **Concurrency**: Async/await with structured concurrency
- **Error Handling**: Comprehensive Swift error types
- **Testing**: XCTest suite with comprehensive coverage

## Performance

The Swift implementation focuses on safety and maintainability:
- Better file size optimization (65% smaller PNGs)
- Comprehensive error recovery
- Memory pressure monitoring
- Structured concurrency for batch operations
- ~33% slower than Objective-C but more robust 