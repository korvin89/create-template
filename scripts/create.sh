#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Parse command line arguments
TARGET_PATH=""
TEMPLATE="js"  # Default template

for arg in "$@"; do
    case $arg in
        path=*)
            TARGET_PATH="${arg#*=}"
            shift
            ;;
        template=*)
            TEMPLATE="${arg#*=}"
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Validate required parameters
if [ -z "$TARGET_PATH" ]; then
    print_error "Missing required parameter: path"
    echo "Usage: bash create.sh path=<directory> [template=<type>]"
    echo "Example: bash create.sh path=./my-project"
    echo "Example with specific template: bash create.sh path=./my-project template=js"
    echo ""
    echo "Default template: js"
    exit 1
fi

# Determine the script location
# If run via curl, we need to fetch files from GitHub
# If run locally, use the local templates directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$REPO_ROOT/templates"

# Check if we're running locally or via curl
if [ -d "$TEMPLATES_DIR" ]; then
    print_info "Running in local mode"
    LOCAL_MODE=true
else
    print_error "Templates directory not found. Remote mode via curl is not yet supported."
    print_error "Please run this script from a local clone of the repository."
    exit 1
fi

print_info "Creating project at: $TARGET_PATH"

# Create target directory
if [ -d "$TARGET_PATH" ]; then
    print_warning "Directory $TARGET_PATH already exists"
    read -p "Do you want to continue? Files may be overwritten. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted."
        exit 0
    fi
else
    print_info "Creating directory: $TARGET_PATH"
    mkdir -p "$TARGET_PATH"
fi

# Convert to absolute path
TARGET_PATH="$(cd "$TARGET_PATH" && pwd)"

# Copy common templates
print_info "Copying common template files..."
COMMON_DIR="$TEMPLATES_DIR/common"
if [ ! -d "$COMMON_DIR" ]; then
    print_error "Common templates directory not found: $COMMON_DIR"
    exit 1
fi

# Copy all files from common directory (including hidden files)
cp -r "$COMMON_DIR"/. "$TARGET_PATH/"
print_info "✓ Common files copied"

# Copy template-specific files
print_info "Copying $TEMPLATE template files..."
TEMPLATE_DIR="$TEMPLATES_DIR/$TEMPLATE"

if [ ! -d "$TEMPLATE_DIR" ]; then
    print_error "Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Copy all files from template directory
cp -r "$TEMPLATE_DIR"/. "$TARGET_PATH/"
print_info "✓ Template files copied"

# Change to target directory
cd "$TARGET_PATH"

# Check if package.json exists (required for npm operations)
if [ ! -f "package.json" ]; then
    print_error "package.json not found in target directory"
    print_error "The selected template may not include a package.json file"
    exit 1
fi

# Install npm dependencies
print_info "Installing npm dependencies..."
if npm install; then
    print_info "✓ Dependencies installed"
else
    print_error "Failed to install dependencies"
    exit 1
fi

# Initialize husky
print_info "Initializing husky..."
if npm run prepare; then
    print_info "✓ Husky initialized"
else
    print_warning "Failed to initialize husky (this may be normal if git repo is not initialized)"
fi

# Success message
echo ""
print_info "=========================================="
print_info "Project successfully created at: $TARGET_PATH"
print_info "Template: $TEMPLATE"
print_info "=========================================="
echo ""
print_info "Next steps:"
echo "  1. cd $TARGET_PATH"
echo "  2. Initialize git repository: git init"
echo "  3. Update placeholders in package.json (<project-name>, <project-description>, etc.)"
echo "  4. Make your first commit: git add . && git commit -m 'Initial commit'"
echo ""

