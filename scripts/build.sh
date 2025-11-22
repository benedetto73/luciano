#!/bin/bash

# Build script for PresentationGenerator
# Automates the build, test, and release process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_NAME="PresentationGenerator"
SCHEME="PresentationGenerator"

# Functions
print_header() {
    echo -e "\n${GREEN}===================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===================================${NC}\n"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Clean build
clean_build() {
    print_header "Cleaning Build"
    swift package clean
    rm -rf .build
    print_success "Clean complete"
}

# Build for debug
build_debug() {
    print_header "Building Debug Configuration"
    swift build --configuration debug
    print_success "Debug build complete"
}

# Build for release
build_release() {
    print_header "Building Release Configuration"
    swift build --configuration release -Xswiftc -O
    print_success "Release build complete"
}

# Run tests
run_tests() {
    print_header "Running Tests"
    print_warning "XCTest not available in SPM executable targets"
    print_warning "Generate Xcode project first: swift package generate-xcodeproj"
    # swift test  # Would run if tests were configured
}

# Generate Xcode project
generate_xcode_project() {
    print_header "Generating Xcode Project"
    swift package generate-xcodeproj
    print_success "Xcode project generated"
}

# Code quality checks
check_code_quality() {
    print_header "Checking Code Quality"
    
    # Check for TODO/FIXME
    echo "Checking for TODOs and FIXMEs..."
    TODO_COUNT=$(find PresentationGenerator -name "*.swift" -exec grep -n "TODO\|FIXME" {} + | wc -l || echo "0")
    echo "Found $TODO_COUNT TODOs/FIXMEs"
    
    # Check for force unwraps
    echo "Checking for force unwraps..."
    FORCE_UNWRAP_COUNT=$(find PresentationGenerator -name "*.swift" -exec grep -n "!" {} + | grep -v "//" | wc -l || echo "0")
    echo "Found approximately $FORCE_UNWRAP_COUNT force unwraps"
    
    # Check for print statements
    echo "Checking for print statements..."
    PRINT_COUNT=$(find PresentationGenerator -name "*.swift" -exec grep -n "print(" {} + | grep -v "//" | wc -l || echo "0")
    echo "Found $PRINT_COUNT print statements"
    
    print_success "Code quality check complete"
}

# Archive for distribution
archive_app() {
    print_header "Archiving Application"
    
    BUILD_DIR=".build/release"
    ARCHIVE_DIR="build/archives"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_NAME="${PROJECT_NAME}_${TIMESTAMP}"
    
    mkdir -p "$ARCHIVE_DIR"
    
    # Build release if not already built
    if [ ! -d "$BUILD_DIR" ]; then
        build_release
    fi
    
    # Create archive
    cd "$BUILD_DIR"
    zip -r "../../../$ARCHIVE_DIR/${ARCHIVE_NAME}.zip" "$PROJECT_NAME"
    cd - > /dev/null
    
    print_success "Archive created: $ARCHIVE_DIR/${ARCHIVE_NAME}.zip"
}

# Display help
show_help() {
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  clean       - Clean build artifacts"
    echo "  debug       - Build debug configuration"
    echo "  release     - Build release configuration"
    echo "  test        - Run tests"
    echo "  xcode       - Generate Xcode project"
    echo "  check       - Run code quality checks"
    echo "  archive     - Create distribution archive"
    echo "  all         - Clean, build release, and run tests"
    echo "  help        - Show this help message"
    echo ""
}

# Main execution
case "${1:-help}" in
    clean)
        clean_build
        ;;
    debug)
        build_debug
        ;;
    release)
        build_release
        ;;
    test)
        run_tests
        ;;
    xcode)
        generate_xcode_project
        ;;
    check)
        check_code_quality
        ;;
    archive)
        archive_app
        ;;
    all)
        clean_build
        build_release
        check_code_quality
        run_tests
        ;;
    help|*)
        show_help
        ;;
esac

exit 0
