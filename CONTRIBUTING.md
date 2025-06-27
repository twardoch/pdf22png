# Contributing to PDF22PNG

First off, thank you for considering contributing to PDF22PNG! It’s people like you that make this such a great tool.

This document provides guidelines for contributing to the project. Please read it carefully to ensure a smooth and effective contribution process.

## How Can I Contribute?

There are many ways to contribute, from writing code and documentation to reporting bugs and suggesting features. Here are a few ideas:

- **Reporting Bugs**: If you find a bug, please create a [bug report](https://github.com/twardoch/pdf22png/issues/new?template=bug_report.md).
- **Suggesting Enhancements**: If you have an idea for a new feature or an improvement, please create a [feature request](https://github.com/twardoch/pdf22png/issues/new?template=feature_request.md).
- **Writing Code**: If you want to contribute code, please follow the development workflow described below.
- **Improving Documentation**: If you find any part of the documentation unclear or incomplete, please let us know or submit a pull request with your improvements.

## Development Workflow

### 1. Fork the Repository

Start by forking the repository to your own GitHub account.

### 2. Clone the Repository

Clone your forked repository to your local machine:

```bash
git clone https://github.com/YOUR-USERNAME/pdf22png.git
cd pdf22png
```

### 3. Create a Branch

Create a new branch for your changes:

```bash
git checkout -b feature/your-amazing-feature
```

### 4. Make Your Changes

Now you can start making your changes. Please follow the code standards described below.

### 5. Build and Test

Before submitting your changes, please make sure to build and test them:

```bash
./build.sh
./test_both.sh
```

### 6. Commit Your Changes

Commit your changes with a clear and descriptive commit message:

```bash
git commit -m "feat: Add a new feature"
```

### 7. Push to Your Fork

Push your changes to your forked repository:

```bash
git push origin feature/your-amazing-feature
```

### 8. Create a Pull Request

Finally, create a pull request from your forked repository to the main repository. Please provide a clear and descriptive title and description for your pull request.

## Code Standards

### Objective-C

- Follow the [Apple Coding Guidelines for Cocoa](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html).
- Use 4 spaces for indentation.
- Keep lines under 100 characters.

### Swift

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- Use 4 spaces for indentation.
- Keep lines under 100 characters.

## Project Structure

The project is divided into two main implementations:

- `pdf21png`: The Objective-C implementation, focused on performance and stability.
- `pdf22png`: The Swift implementation, focused on modern features and clean code.

When contributing, please consider which implementation your changes should apply to. If you are unsure, please ask in your pull request.

## License

By contributing to PDF22PNG, you agree that your contributions will be licensed under the MIT License.
