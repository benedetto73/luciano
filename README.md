# PresentationGenerator

A native macOS application that converts text documents into professional presentation slides using OpenAI's API.

## Overview

PresentationGenerator is designed for creating educational presentations for diverse audiences (children and adults). It leverages GPT-4 for intelligent content analysis and slide design, and DALL-E for generating audience-appropriate images.

## Features

- **Intelligent Content Analysis**: Automatically extract key teaching points from Word documents
- **AI-Powered Slide Generation**: Generate slides with appropriate designs, text, and images
- **Audience-Specific Design**: Tailored presentations for Kids or Adults
- **Content Filtering**: Ensures outputs are theologically appropriate for Catholic educational context
- **Full Editing Capabilities**: Edit text, regenerate images, customize designs
- **PowerPoint Export**: Export completed presentations to .pptx format

## Architecture

This project follows a clean architecture pattern:
- **MVVM**: Separation of UI, business logic, and data
- **Coordinator**: Navigation and flow management
- **Repository**: Data access abstraction
- **Dependency Injection**: For testability and modularity

### Directory Structure

```
PresentationGenerator/
├── App/                    # Application entry point and coordinator
├── Models/                 # Domain models and DTOs
├── Views/                  # SwiftUI views and view models
├── Services/               # Business logic services
├── Repositories/           # Data access layer
├── Utilities/              # Extensions, helpers, and constants
├── DependencyInjection/    # DI container and factories
└── Resources/              # Assets, prompts, and localization
```

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- OpenAI API key (with access to GPT-4 and DALL-E)

## Setup

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Build the project (dependencies will be fetched automatically)
4. Run the app and enter your OpenAI API key when prompted

## Development

### Building

```bash
swift build
```

### Testing

```bash
swift test
```

### Running

Open the project in Xcode and run the `PresentationGenerator` scheme.

## Dependencies

- **OpenAI SDK**: For GPT-4 and DALL-E integration
- Additional libraries for Word document parsing (to be added)

## User Flow

1. **Setup**: Enter OpenAI API key (stored securely in Keychain)
2. **Project Creation**: Create a new project and select target audience
3. **Import**: Import one or more Word documents
4. **Analysis**: AI analyzes content and extracts key points
5. **Generation**: AI generates slides with text and images
6. **Editing**: Review and edit slides as needed
7. **Export**: Export to PowerPoint format

## Security & Privacy

- API keys are stored securely in macOS Keychain
- No telemetry or data collection
- All processing is local except OpenAI API calls
- Content filtering ensures appropriate outputs

## License

Copyright © 2025. All rights reserved.

## Version

1.0.0 - Initial Release
