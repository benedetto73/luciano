# PresentationGenerator - User Guide

**Version:** 1.0.0  
**Platform:** macOS 13.0+  
**Last Updated:** November 22, 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Getting Started](#getting-started)
4. [Creating Your First Presentation](#creating-your-first-presentation)
5. [Workflow Guide](#workflow-guide)
6. [Features](#features)
7. [Tips & Best Practices](#tips--best-practices)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Introduction

**PresentationGenerator** is a macOS application that uses AI to automatically create educational presentations from your documents. Simply import your teaching materials, and the app will:

- 📄 **Analyze** your content to extract key teaching points
- 🎨 **Design** slides appropriate for your target audience
- 🤖 **Generate** complete presentations with AI-written content
- 🖼️ **Create** relevant images for each slide
- 📊 **Export** to PowerPoint format (.pptx)

### Who Is This For?

- **Educators** creating teaching materials
- **Religious educators** preparing catechism lessons
- **Presenters** needing quick slide decks
- **Content creators** repurposing written content

---

## Installation

### Requirements

- **macOS**: 13.0 (Ventura) or later
- **OpenAI API Key**: Required for AI features (or use free models)
- **Disk Space**: ~50MB for app + storage for projects

### Download & Install

1. Download `PresentationGenerator.app` from releases
2. Move to `/Applications` folder
3. Double-click to launch
4. Grant necessary permissions when prompted

### First Launch Setup

On first launch, you'll be prompted to:

1. **Enter OpenAI API Key** (or choose "Use Free Models")
2. The app will create required directories:
   - `~/Documents/PresentationGenerator/Projects`
   - `~/Documents/PresentationGenerator/Images`
   - `~/Documents/PresentationGenerator/Exports`

---

## Getting Started

### Understanding the Workflow

PresentationGenerator follows a **4-step workflow**:

```
1. Import → 2. Analyze → 3. Generate → 4. Export
```

Each step builds on the previous one to create your final presentation.

### Main Screen Overview

```
┌─────────────────────────────────────────┐
│  PresentationGenerator          ⚙️  ➕  │
├─────────────────────────────────────────┤
│                                         │
│  📁 My Projects                         │
│  ├─ Catholic Beatitudes (5 slides)      │
│  ├─ Ten Commandments (10 slides)        │
│  └─ Sacraments Overview (7 slides)      │
│                                         │
└─────────────────────────────────────────┘
```

**Controls:**
- ⚙️ **Settings** - Configure API key, preferences
- ➕ **New Project** - Create a new presentation
- 🔍 **Search** - Find projects by name

---

## Creating Your First Presentation

### Step-by-Step Tutorial

#### 1. Create a New Project

1. Click the **➕** button in the toolbar
2. Enter a **project name** (e.g., "The Beatitudes")
3. Select your **target audience**:
   - 👶 **Kids** (6-12 years) - Large fonts, bright colors, simple layouts
   - 🎒 **Teenagers** (13-17 years) - Medium fonts, engaging visuals
   - 👨 **Adults** (18-64 years) - Professional design, detailed content
   - 👴 **Seniors** (65+ years) - Extra large fonts, high contrast
   - 💼 **Professionals** - Dense content, minimal design
4. Click **Create Project**

#### 2. Import Source Documents

1. Click **Import Content** button
2. Choose your source files:
   - ✅ `.txt` - Plain text files
   - ✅ `.rtf` - Rich text format
   - ✅ `.doc` - Microsoft Word (legacy)
   - ✅ `.docx` - Microsoft Word (modern)
3. Or **drag and drop** files directly
4. Review imported files in the list

**Tip:** You can import multiple files - they'll all be analyzed together.

#### 3. Analyze Content

1. Click **Analyze Content** button
2. The AI will:
   - Read your documents
   - Extract key teaching points
   - Suggest number of slides (typically 1 point = 1 slide)
3. Review the **key points** list
4. Edit any points if needed:
   - Click pencil icon ✏️ to edit
   - Drag to reorder
   - Delete unwanted points

**Example Key Points:**
```
1. Blessed are the poor in spirit, for theirs is the kingdom of heaven
2. Blessed are those who mourn, for they will be comforted
3. Blessed are the meek, for they will inherit the earth
...
```

#### 4. Generate Slides

1. Click **Generate Slides** button
2. Watch real-time progress:
   - Content generation (AI writes slide text)
   - Image generation (AI creates visuals)
   - Slide assembly
3. Wait for completion (typically 2-5 minutes)

**Progress Example:**
```
Generating slide 3 of 5...
⬛⬛⬛⬜⬜ 60%
```

#### 5. Review & Edit Slides

1. Browse generated slides in thumbnail view
2. Click any slide to edit:
   - **Title** - Slide heading
   - **Content** - Main text/bullet points
   - **Notes** - Speaker notes
   - **Image** - Upload custom image or regenerate
3. **Reorder slides** by dragging thumbnails
4. **Delete slides** by clicking trash icon

**Auto-save:** Changes are automatically saved every 2 seconds.

#### 6. Export Presentation

1. Click **Export** button
2. Choose export location (default: `~/Downloads`)
3. Wait for export to complete
4. Options:
   - **Show in Finder** - Open export location
   - **Share** - Share via Mail, Messages, AirDrop

Your `.pptx` file is ready to use in PowerPoint, Keynote, or Google Slides!

---

## Workflow Guide

### Import Content Best Practices

**Recommended Content:**
- ✅ Well-structured documents with clear sections
- ✅ 500-5000 words (optimal range)
- ✅ Focused on a single topic
- ✅ Teaching materials, articles, lesson plans

**Avoid:**
- ❌ Very short documents (<200 words)
- ❌ Very long documents (>10,000 words)
- ❌ Documents with mixed topics
- ❌ Tables, charts, code (text content only)

### Content Analysis Tips

**Getting Better Key Points:**
1. **Clear Writing** - Well-organized source documents produce better results
2. **Topic Focus** - Single topic = more coherent presentation
3. **Manual Editing** - Review and refine AI-extracted points
4. **Reorder Points** - Arrange in logical teaching sequence

**Key Point Quality Checklist:**
- [ ] Each point is clear and specific
- [ ] Points flow in logical order
- [ ] No duplicate or overlapping points
- [ ] Appropriate detail level for audience

### Slide Generation Options

**Audience Affects:**
- **Font Size**: Kids/Seniors get larger text
- **Colors**: Bright for kids, professional for adults
- **Layout**: Simple for kids/seniors, detailed for professionals
- **Language**: Age-appropriate vocabulary and concepts

**Image Generation:**
- AI creates relevant images based on slide content
- Images are saved locally for offline use
- You can upload custom images to replace AI-generated ones

### Editing Slides

**Common Edits:**
1. **Shorten text** - Keep slides concise
2. **Add emphasis** - Highlight key words
3. **Reorder bullets** - Most important first
4. **Add notes** - Speaker notes for presenting

**Keyboard Shortcuts:**
- `⌘N` - New Project
- `⌘S` - Save (auto-saves anyway)
- `⌘E` - Export
- `⌘,` - Settings

---

## Features

### Audience-Specific Design

Each audience type gets optimized design:

| Audience | Font Size | Layout | Colors |
|----------|-----------|--------|--------|
| Kids | Large | Simple | Bright, playful |
| Teenagers | Medium | Moderate | Engaging, modern |
| Adults | Medium | Balanced | Professional |
| Seniors | Extra Large | Simple | High contrast |
| Professionals | Small | Dense | Minimal, clean |

### AI-Powered Content

**Content Analysis:**
- Extracts main teaching points
- Identifies key concepts
- Suggests slide count
- Maintains topic coherence

**Slide Generation:**
- Creates slide titles
- Writes bullet points
- Generates speaker notes
- Suggests relevant images

**Image Generation:**
- Context-aware visuals
- Audience-appropriate style
- Catholic/religious themes supported
- Educational illustrations

### Project Management

**Features:**
- **Search** - Find projects quickly
- **Sort** - By date or name
- **Duplicate** - Copy projects
- **Export/Import** - Share projects
- **Delete** - With confirmation

### Auto-Save

- Saves every 2 seconds while editing
- No manual save needed
- Changes preserved automatically
- Works even if app crashes

---

## Tips & Best Practices

### Content Preparation

1. **Clean Your Documents**
   - Remove formatting artifacts
   - Fix typos and grammar
   - Organize with clear sections

2. **Optimal Length**
   - Aim for 1000-3000 words
   - About 5-15 slides worth
   - One main topic per document

3. **Structure Matters**
   - Use headings for main points
   - Paragraphs for elaboration
   - Lists for key items

### Working with AI

1. **Review Everything**
   - AI is helpful but not perfect
   - Always review generated content
   - Edit for accuracy and clarity

2. **Iterate**
   - Generate → Review → Edit → Regenerate
   - Try different prompts
   - Refine key points

3. **Provide Context**
   - More context = better results
   - Explain concepts clearly
   - Use specific terminology

### Presentation Design

1. **Less is More**
   - 3-5 bullet points per slide
   - Short, punchy text
   - One main idea per slide

2. **Consistent Style**
   - Stick to one audience type
   - Maintain design throughout
   - Use consistent terminology

3. **Visual Balance**
   - Mix text and image slides
   - Don't overcrowd slides
   - Leave white space

---

## Troubleshooting

### Common Issues

#### "Invalid API Key" Error

**Solution:**
1. Go to Settings (⚙️)
2. Click "Update API Key"
3. Enter valid OpenAI API key
4. Or select "Use Free Models"

**Get API Key:**
- Visit: https://platform.openai.com/api-keys
- Sign up for OpenAI account
- Create new API key
- Copy and paste into app

#### No Slides Generated

**Possible Causes:**
1. **Empty content** - Import failed
2. **API error** - Check API key
3. **Network issue** - Check internet connection

**Solutions:**
- Verify documents imported successfully
- Check API key is valid
- Ensure internet connection active
- Try with smaller document first

#### Slow Generation

**Normal Times:**
- 5 slides: ~2-3 minutes
- 10 slides: ~5-7 minutes
- 20 slides: ~10-15 minutes

**Speed Up:**
- Use fewer key points
- Split into multiple projects
- Check network speed

#### Export Failed

**Solutions:**
1. Check disk space (need ~10MB per project)
2. Ensure export location is writable
3. Close PowerPoint if file is open
4. Try different export location

### Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| Insufficient Content | Document too short | Add more content or combine files |
| API Rate Limit | Too many requests | Wait 1 minute, try again |
| Network Error | No internet | Check connection, retry |
| File Not Found | Missing image | Regenerate slide images |

---

## FAQ

### General Questions

**Q: Do I need an OpenAI API key?**  
A: Yes for full features, but you can use free models with limited functionality.

**Q: How much does it cost?**  
A: The app is free. OpenAI API usage costs ~$0.10-0.50 per presentation depending on length.

**Q: Can I use it offline?**  
A: No, AI features require internet. But you can edit existing projects offline.

**Q: What file formats are supported?**  
A: Import: TXT, RTF, DOC, DOCX. Export: PPTX (PowerPoint).

### Content Questions

**Q: What makes good source content?**  
A: Well-written, structured documents on a single topic, 1000-3000 words ideal.

**Q: Can I import PDFs?**  
A: Not directly. Copy text from PDF and save as TXT file first.

**Q: How many slides should I create?**  
A: Generally 1 slide per key point. 5-15 slides works well for most presentations.

**Q: Can I edit generated content?**  
A: Yes! Edit titles, content, notes, and images. Changes auto-save.

### Technical Questions

**Q: Where are projects stored?**  
A: `~/Documents/PresentationGenerator/Projects/` as JSON files.

**Q: Can I share projects?**  
A: Yes, use Export Project to share .json file, then Import on another Mac.

**Q: What happens if I delete the app?**  
A: Projects remain in Documents folder. Reinstall app to access them.

**Q: Is my data private?**  
A: Documents are sent to OpenAI for processing. See their privacy policy. Projects stored locally.

### Audience Questions

**Q: Can I change audience after creation?**  
A: You'll need to regenerate slides for new design. Key points remain same.

**Q: What's the difference between Kids and Teenagers?**  
A: Font size, color brightness, language complexity, and content depth.

**Q: Should I use "Professionals" for academic presentations?**  
A: Yes, it's best for detailed, information-dense presentations.

---

## Support & Resources

### Getting Help

- **Documentation**: This guide
- **API Reference**: `API_DOCUMENTATION.md`
- **Architecture**: `ARCHITECTURE.md`
- **Issues**: GitHub Issues

### OpenAI Resources

- **API Documentation**: https://platform.openai.com/docs
- **Pricing**: https://openai.com/pricing
- **Support**: https://help.openai.com

### Credits

Built with:
- Swift & SwiftUI
- OpenAI GPT-4 & DALL-E
- macOS 13.0+ Frameworks

---

**Happy Presenting! 🎉**

For questions or feedback, please visit our GitHub repository.
