# create-template

Bash script for bootstrapping a clean JS/TS project with common tooling.

## Installation

To create a new project, run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/korvin89/create-template/main/scripts/create.sh | bash -s -- path=./my-project
```

This will download and execute the `create.sh` script, which will:
- Copy common configuration files (editorconfig, gitignore, prettier, etc.)
- Copy template-specific files (package.json, eslint config, etc.)
- Install npm dependencies
- Initialize git repository
- Initialize husky git hooks

## Manual Installation

If you prefer not to execute scripts directly from the web, you can clone this repository and run the script manually:

```bash
git clone https://github.com/korvin89/create-template.git
cd create-template
./scripts/create.sh path=./my-project
```

## Usage

The script accepts the following parameters:

- `path=<directory>` - **Required**. The path where the project will be created
- `template=<type>` - **Optional**. The template type to use (default: `js`)

### Examples

Create a new project with default template (js):

```bash
curl -fsSL https://raw.githubusercontent.com/korvin89/create-template/main/scripts/create.sh | bash -s -- path=./my-app
```

Create a project with a specific template:

```bash
curl -fsSL https://raw.githubusercontent.com/korvin89/create-template/main/scripts/create.sh | bash -s -- path=./my-app template=js
```

## What Gets Installed

### Common Files (always installed)

- `.editorconfig` - Editor configuration
- `.gitignore` - Git ignore rules
- `.nvmrc` - Node version specification
- `.prettierrc.js` - Prettier configuration
- `commitlint.config.js` - Commit linting rules

### Template: JS (default)

- `package.json` - NPM package configuration with scripts and dependencies
- `eslint.config.mjs` - ESLint configuration

## Post-Installation

After installation, don't forget to:

1. Navigate to your project directory:
   ```bash
   cd ./my-project
   ```

2. Update placeholders in `package.json`:
   - `<project-name>` - Your project name
   - `<project-description>` - Your project description
   - `<project-owner>` - Your GitHub username

3. Make your first commit:
   ```bash
   git add .
   git commit -m "Initial commit"
   ```

## Requirements

- Node.js >= 22
- npm >= 10
- Git (for husky hooks to work properly)
