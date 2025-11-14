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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR" 2>/dev/null)"
TEMPLATES_DIR="$REPO_ROOT/templates"

# GitHub repository settings
GITHUB_USER="korvin89"
GITHUB_REPO="create-template"
GITHUB_BRANCH="main"
GITHUB_RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH"

# Check if we're running locally or via curl
if [ -d "$TEMPLATES_DIR" ]; then
    print_info "Running in local mode"
    LOCAL_MODE=true
else
    print_info "Running in remote mode (downloading from GitHub)"
    LOCAL_MODE=false
fi

print_info "Creating project at: $TARGET_PATH"

# Check if target directory already exists
if [ -d "$TARGET_PATH" ]; then
    print_error "Directory $TARGET_PATH already exists"
    print_error "Please choose a different path or remove the existing directory"
    exit 1
fi

# Create target directory
print_info "Creating directory: $TARGET_PATH"
mkdir -p "$TARGET_PATH"

# Convert to absolute path
TARGET_PATH="$(cd "$TARGET_PATH" && pwd)"

# Function to download file from GitHub
download_file() {
    local remote_path=$1
    local local_path=$2
    local url="$GITHUB_RAW_URL/$remote_path"
    
    if curl -fsSL "$url" -o "$local_path"; then
        return 0
    else
        print_error "Failed to download: $url"
        return 1
    fi
}

# Copy/download common templates
print_info "Copying common template files..."

if [ "$LOCAL_MODE" = true ]; then
    # Local mode: copy files
    COMMON_DIR="$TEMPLATES_DIR/common"
    if [ ! -d "$COMMON_DIR" ]; then
        print_error "Common templates directory not found: $COMMON_DIR"
        exit 1
    fi
    cp -r "$COMMON_DIR"/. "$TARGET_PATH/"
else
    # Remote mode: download files from GitHub
    COMMON_FILES=(
        ".editorconfig"
        ".gitignore"
        ".nvmrc"
        ".prettierrc.js"
        "commitlint.config.js"
    )
    
    for file in "${COMMON_FILES[@]}"; do
        download_file "templates/common/$file" "$TARGET_PATH/$file" || exit 1
    done
fi

print_info "✓ Common files copied"

# Copy/download template-specific files
print_info "Copying $TEMPLATE template files..."

if [ "$LOCAL_MODE" = true ]; then
    # Local mode: copy files
    TEMPLATE_DIR="$TEMPLATES_DIR/$TEMPLATE"
    
    if [ ! -d "$TEMPLATE_DIR" ]; then
        print_error "Template directory not found: $TEMPLATE_DIR"
        exit 1
    fi
    
    cp -r "$TEMPLATE_DIR"/. "$TARGET_PATH/"
else
    # Remote mode: download files from GitHub
    if [ "$TEMPLATE" = "js" ]; then
        TEMPLATE_FILES=(
            "package.json"
            "eslint.config.mjs"
        )
        
        for file in "${TEMPLATE_FILES[@]}"; do
            download_file "templates/js/$file" "$TARGET_PATH/$file" || exit 1
        done
    elif [ "$TEMPLATE" = "ts" ]; then
        TEMPLATE_FILES=(
            "package.json"
            "eslint.config.mjs"
            "tsconfig.json"
        )
        
        for file in "${TEMPLATE_FILES[@]}"; do
            download_file "templates/ts/$file" "$TARGET_PATH/$file" || exit 1
        done
        
        # Create src directory and download source files
        mkdir -p "$TARGET_PATH/src"
        download_file "templates/ts/src/index.ts" "$TARGET_PATH/src/index.ts" || exit 1
    else
        print_error "Unknown template: $TEMPLATE"
        print_error "Available templates: js, ts"
        exit 1
    fi
fi

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

# Initialize git repository
print_info "Initializing git repository..."
if git init; then
    print_info "✓ Git repository initialized"
else
    print_error "Failed to initialize git repository"
    exit 1
fi

# Initialize husky
print_info "Initializing husky..."
if npx husky init; then
    print_info "✓ Husky initialized"
    
    # Create pre-commit hook for nano-staged
    cat > .husky/pre-commit << 'EOF'
npx nano-staged
EOF
    chmod +x .husky/pre-commit
    print_info "✓ Pre-commit hook created"
else
    print_error "Failed to initialize husky"
    exit 1
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
echo "  2. Update placeholders in package.json (<project-name>, <project-description>, etc.)"
echo "  3. Make your first commit: git add . && git commit -m 'Initial commit'"
echo ""

