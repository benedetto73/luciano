
MacOS Presentation Generator App - Development Specification
Project Overview
Build a native macOS application that converts text documents into professional presentation slides using OpenAI's API. The app is designed for a Catholic priest who creates educational content for diverse audiences (children and adults).
Technology Stack

Platform: macOS (SwiftUI + Swift)
AI Integration: OpenAI API (GPT-4 for text/design, DALL-E for images)
File Handling: Support .doc/.docx import, .pptx export
Storage: Keychain for API keys, JSON/serialized format for projects

Core Features
1. First Launch & Configuration

Prompt user for OpenAI API key on first run
Store API key securely in macOS Keychain
Validate API key before proceeding
Settings panel to view/update API key later

2. Project Management

Create new project workflow
Project Creation Dialog: Ask target audience (Kids/Adults) - this affects design decisions
One project open at a time
Save projects to disk in serialized format (JSON recommended)
Project browser: List all saved projects with metadata (name, date, audience type)
Reopen and edit existing projects

3. Import Phase

Support importing multiple text files per project
File types: .doc, .docx
Display imported file names and preview content
Combine multiple files into single project context

4. Phase 1: Content Analysis

Send imported text to OpenAI GPT-4 with prompt to:

Extract key teaching points
Suggest optimal number of slides
Consider target audience (kids/adults) in recommendations


Display results in editable UI:

List of key points (add/remove/edit)
Number of slides (adjustable)


Content Filtering: Include prompt instructions to ensure religious/educational appropriateness
Show loading indicator during API processing
"Proceed to Slide Generation" button

5. Phase 2: Slide Generation
For each slide sequentially:

Use GPT-4 to generate:

Slide design specification (layout, colors, fonts - appropriate for audience)
Text content (title, body, bullet points)
Image description/prompt


Use DALL-E to generate image from description
Display slide preview with:

Generated image
Generated text
Design layout preview



User Editing Per Slide:

Edit text content (inline editing)
Regenerate image (new DALL-E prompt)
Upload custom image (replace generated one)
Adjust layout/design elements
Navigation: Previous/Next slide buttons
Slide counter: "Slide X of Y"

6. Slide Management

Overview mode: Thumbnail view of all slides
Reorder slides (drag and drop)
Add new slides manually
Delete slides
Duplicate slides

7. Export

"Generate PowerPoint" button
Export all slides to .pptx format
Preserve all images, text, and formatting
Show success message with file location
Option to save project after export

UI/UX Requirements
Visual Design

Modern macOS native appearance
Follow macOS Human Interface Guidelines
Clean, minimal interface suitable for non-technical users
Light/Dark mode support

User Flow
Start → API Key Setup (first time) → 
New/Open Project → Select Audience → 
Import Files → 
Phase 1: Review Key Points & Slide Count → 
Phase 2: Generate & Edit Slides (one by one) → 
Review All Slides → 
Export to PowerPoint
Feedback & Progress

Loading spinners during API calls
Progress bars for multi-slide generation
Error messages for API failures, invalid files, network issues
Success confirmations
Estimated time remaining for long operations

Technical Requirements
Error Handling

API key validation and helpful error messages
Network connectivity checks
OpenAI API rate limiting handling
File import error handling (corrupted files, unsupported formats)
Graceful degradation if API fails mid-generation

Data Persistence

Project File Structure:

json  {
    "projectName": "string",
    "audience": "kids|adults",
    "createdDate": "ISO date",
    "modifiedDate": "ISO date",
    "sourceFiles": ["filenames"],
    "keyPoints": ["array of strings"],
    "slides": [
      {
        "slideNumber": 1,
        "title": "string",
        "content": "string",
        "imageUrl": "local file path or base64",
        "designSpec": { layout details },
        "notes": "string"
      }
    ]
  }

Save projects to ~/Documents/PresentationProjects/
Auto-save during editing

OpenAI Integration

Content Filtering Prompt: Include system message ensuring outputs are:

Theologically appropriate for Catholic teaching
Age-appropriate for specified audience
Educational and respectful
Free from controversial or inappropriate content



Performance

Async/await for all API calls
Cancel ongoing API requests if user navigates away
Cache generated images locally
Reasonable timeouts for API requests

Security & Privacy

Never log or expose API keys
Use macOS Keychain Services API
No telemetry or data collection
Local-only processing (except OpenAI API calls)

File Dependencies

Import: Microsoft Word document parsing library
Export: PowerPoint generation library (e.g., python-pptx via bridge, or native Swift solution)
OpenAI SDK: Official Swift SDK or REST API client

Nice-to-Have Features (Future)

Undo/redo functionality
Custom fonts selection
Background music/audio notes
Print preview
PDF export option
Batch project generation

Development Phases

Phase 1: Basic UI shell, project management, API key storage
Phase 2: File import, OpenAI integration for Phase 1 (content analysis)
Phase 3: Slide generation (Phase 2), editing interface
Phase 4: PowerPoint export functionality
Phase 5: Polish, error handling, testing

Testing Checklist

 API key validation and secure storage
 Import various Word document formats
 Content filtering for appropriateness
 Kids vs Adults audience differentiation
 All editing features work correctly
 PowerPoint export maintains quality
 Project save/load functionality
 Error handling for network/API failures
 Performance with large documents

