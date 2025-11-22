# Contributing to PresentationGenerator

Thank you for your interest in contributing to PresentationGenerator! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Making Changes](#making-changes)
5. [Testing](#testing)
6. [Code Style](#code-style)
7. [Commit Guidelines](#commit-guidelines)
8. [Pull Request Process](#pull-request-process)
9. [Issue Guidelines](#issue-guidelines)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, gender, gender identity, sexual orientation, disability, personal appearance, race, ethnicity, age, religion, or nationality.

### Expected Behavior

- **Be respectful** and considerate in all interactions
- **Be collaborative** and helpful to other contributors
- **Accept constructive criticism** gracefully
- **Focus on what is best** for the community and project

### Unacceptable Behavior

- Harassment, discrimination, or trolling
- Personal attacks or insults
- Publishing others' private information
- Any conduct that would be inappropriate in a professional setting

---

## Getting Started

### Prerequisites

- **macOS** 13.0+ (Ventura or later)
- **Xcode** 15.0+ with Command Line Tools
- **Swift** 5.9+
- **Git** for version control
- **OpenAI API Key** for testing (optional, can use mock service)

### Fork and Clone

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:

```bash
git clone https://github.com/YOUR_USERNAME/luciano.git
cd luciano
```

3. **Add upstream** remote:

```bash
git remote add upstream https://github.com/benedetto73/luciano.git
```

4. **Verify** remotes:

```bash
git remote -v
# origin    https://github.com/YOUR_USERNAME/luciano.git (fetch)
# origin    https://github.com/YOUR_USERNAME/luciano.git (push)
# upstream  https://github.com/benedetto73/luciano.git (fetch)
# upstream  https://github.com/benedetto73/luciano.git (push)
```

---

## Development Setup

### Build the Project

```bash
# Resolve dependencies
swift package resolve

# Build
swift build

# Run (if executable)
swift run PresentationGenerator
```

### Generate Xcode Project (for testing)

```bash
swift package generate-xcodeproj
open PresentationGenerator.xcodeproj
```

### Install Dependencies

Dependencies are managed via Swift Package Manager (SPM):

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/MacPaw/OpenAI", from: "0.2.4")
]
```

No manual installation needed - SPM handles it automatically.

---

## Making Changes

### Create a Branch

Always create a new branch for your changes:

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or bug fix branch
git checkout -b fix/bug-description
```

**Branch Naming Convention:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes

### Make Your Changes

1. **Edit code** following our [Code Style](#code-style)
2. **Add tests** for new functionality
3. **Update documentation** if needed
4. **Test thoroughly** before committing

### Keep Your Branch Updated

```bash
# Fetch upstream changes
git fetch upstream

# Rebase your branch
git rebase upstream/main

# Or merge if you prefer
git merge upstream/main
```

---

## Testing

### Running Tests

**Note:** Due to XCTest limitations with SPM executable targets, you must generate an Xcode project first:

```bash
# Generate Xcode project
swift package generate-xcodeproj

# Run tests in Xcode
xcodebuild test -scheme PresentationGenerator

# Or open in Xcode and use ⌘U
open PresentationGenerator.xcodeproj
```

### Writing Tests

All new features should include tests:

```swift
import XCTest
@testable import PresentationGenerator

@MainActor
final class MyFeatureTests: XCTestCase {
    var sut: MyFeature!
    
    override func setUp() async throws {
        sut = MyFeature()
    }
    
    override func tearDown() async throws {
        sut = nil
    }
    
    func testMyFeature_WithValidInput_ReturnsExpectedResult() async throws {
        // Given
        let input = "test input"
        
        // When
        let result = try await sut.process(input)
        
        // Then
        XCTAssertEqual(result, "expected output")
    }
}
```

### Test Coverage Goals

- **Services**: 80%+ coverage
- **Repositories**: 70%+ coverage
- **ViewModels**: 60%+ coverage
- **Critical paths**: 100% coverage

---

## Code Style

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

**Key Points:**

```swift
// GOOD: Clear, descriptive names
func generateSlides(from analysis: ContentAnalysisResult) async throws -> [Slide]

// BAD: Abbreviated, unclear
func genSlides(ana: CAR) async throws -> [Slide]
```

```swift
// GOOD: Proper use of whitespace
if condition {
    doSomething()
}

// BAD: Cramped
if condition{doSomething()}
```

```swift
// GOOD: Meaningful constants
let maximumSlideCount = 50

// BAD: Magic numbers
if slides.count > 50 {
    // ...
}
```

### Code Organization

```swift
// MARK: - Section Name

class MyClass {
    // MARK: - Properties
    
    private let dependency: Dependency
    @Published var state: State
    
    // MARK: - Initialization
    
    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    // MARK: - Public Methods
    
    func publicMethod() {
        // ...
    }
    
    // MARK: - Private Methods
    
    private func privateHelper() {
        // ...
    }
}
```

### Documentation Comments

Use DocC-style comments for public APIs:

```swift
/// Analyzes source content and extracts key teaching points.
///
/// This method processes the provided content using AI to identify
/// the main teaching points suitable for presentation slides.
///
/// - Parameters:
///   - content: The text content to analyze
///   - audience: Target audience for content adaptation
/// - Returns: Analysis result containing key points and suggestions
/// - Throws: `AppError.insufficientContent` if content is too short
///          `OpenAIError` if API call fails
func analyze(
    content: String,
    audience: Audience
) async throws -> ContentAnalysisResult {
    // Implementation
}
```

### Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line length**: 120 characters max
- **Trailing whitespace**: None
- **File endings**: Single newline

---

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (no logic change)
- `refactor`: Code restructuring
- `test`: Adding or fixing tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(SlideGenerator): Add support for custom templates

- Added TemplateManager service
- Implemented template selection UI
- Updated SlideGenerator to use templates

Closes #42
```

```
fix(Export): Resolve PowerPoint export crash

Fixed null reference exception when exporting projects
without images.

Fixes #58
```

```
docs(README): Update installation instructions

Added section on obtaining OpenAI API key and
clarified macOS version requirements.
```

### Atomic Commits

- **One logical change** per commit
- **Keep commits small** and focused
- **Commit often** rather than large batches
- **Ensure each commit builds** and passes tests

---

## Pull Request Process

### Before Submitting

- [ ] Code builds without errors
- [ ] All tests pass
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Code follows style guidelines
- [ ] Commits are atomic and well-described
- [ ] Branch is up to date with main

### Creating a Pull Request

1. **Push your branch**:

```bash
git push origin feature/your-feature-name
```

2. **Open PR** on GitHub

3. **Fill out PR template**:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have commented my code where needed
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
```

4. **Wait for review**

### Code Review Process

- **At least one approval** required
- **All discussions resolved** before merge
- **CI checks passing** (when implemented)
- **Maintainer merges** approved PRs

### Review Feedback

- **Be responsive** to review comments
- **Make requested changes** promptly
- **Ask questions** if feedback is unclear
- **Be open** to suggestions

---

## Issue Guidelines

### Before Opening an Issue

1. **Search existing issues** to avoid duplicates
2. **Try latest version** to ensure bug still exists
3. **Gather information** about the problem

### Bug Reports

Use this template:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - macOS Version: [e.g. 13.0]
 - App Version: [e.g. 1.0.0]

**Additional context**
Any other relevant information.
```

### Feature Requests

Use this template:

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features.

**Additional context**
Any other context or screenshots.
```

### Enhancement Proposals

For significant changes, open a discussion first:

1. Create **Discussion** (not Issue)
2. Describe the proposal
3. Gather community feedback
4. Create Issue/PR after consensus

---

## Areas for Contribution

### Good First Issues

Look for issues labeled `good first issue`:
- Documentation improvements
- Simple bug fixes
- Test additions
- UI polish

### High Priority

- **PowerPoint Export** - Complete XML generation
- **Document Parsing** - Add DOC/DOCX support
- **Performance** - Optimize for large projects
- **Error Handling** - Improve error messages

### Feature Ideas

- Additional audience types
- More slide layouts
- Custom templates
- Collaboration features
- Cloud sync
- Mobile companion app

---

## Getting Help

### Resources

- **Documentation**: See `/docs` folder
- **Architecture**: `ARCHITECTURE.md`
- **API Reference**: `API_DOCUMENTATION.md`
- **User Guide**: `USER_GUIDE.md`

### Contact

- **GitHub Discussions**: For questions and ideas
- **GitHub Issues**: For bugs and features
- **Email**: [maintainer email]

---

## Recognition

Contributors will be:
- Listed in `CONTRIBUTORS.md`
- Mentioned in release notes
- Credited in the app (for significant contributions)

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see `LICENSE` file).

---

**Thank you for contributing to PresentationGenerator! 🎉**

Your efforts help make this tool better for educators and presenters everywhere.
