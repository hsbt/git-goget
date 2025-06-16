# git-goget

A command-line tool to clone Git repositories to a structured directory layout.

## Overview

`git-goget` is a command-line tool that clones Git repositories to a structured directory layout under a configurable root directory. It supports various Git hosting services including GitHub, GitLab, Bitbucket, and others, following the pattern used by Go's workspace organization.

The tool operates silently without producing output unless there are errors.

## Installation

### Prerequisites

- [Git](https://git-scm.com/)

### Manual Installation

1. Clone this repository or download the script
   ```bash
   git clone https://github.com/hsbt/git-goget.git
   ```

2. Make the script executable
   ```bash
   chmod +x git-goget/git-goget
   ```

3. Add the script to your PATH
   ```bash
   # Copy to a directory in your PATH
   cp git-goget/git-goget /usr/local/bin/
   
   # Or create a symlink
   ln -s /path/to/git-goget/git-goget /usr/local/bin/git-goget
   ```

4. Verify installation
   ```bash
   git goget version
   ```

## Usage

Clone a Git repository to the structured directory:

```bash
git goget <git-url>
```

Clone to a custom root directory:

```bash
git goget --root <directory> <git-url>
```

Show the tool version:

```bash
git goget version
```

Display help information:

```bash
git goget --help
```

## Root Directory Priority

The root directory is determined by the following priority:

1. **--root option** (highest priority)
2. **GIT_GOGET_ROOT environment variable**
3. **git config user.rootDirectory value**
4. **~/src** (default fallback)

### Examples

```bash
# Clone Rails repository (uses priority system for root directory)
git goget https://github.com/rails/rails

# Set environment variable for session
export GIT_GOGET_ROOT=~/workspace
git goget https://github.com/rails/rails
# Clones to ~/workspace/github.com/rails/rails

# Set global default via git config
git config user.rootDirectory ~/myprojects
git goget https://gitlab.com/gitlab-org/gitlab
# Clones to ~/myprojects/gitlab.com/gitlab-org/gitlab

# Override with --root option
git goget --root ~/Documents https://github.com/rails/rails
# Clones to ~/Documents/github.com/rails/rails

# Clone using SSH URL
git goget git@github.com:rails/rails.git

# Show version information
git goget version
```

## Directory Structure

The tool creates repositories in this structure:

With default root (`~/src`):
```
~/src/
├── github.com/
│   ├── rails/
│   │   └── rails/          # GitHub repository
│   └── hsbt/
│       └── gh-coauthor/
├── gitlab.com/
│   └── gitlab-org/
│       └── gitlab/         # GitLab repository
├── bitbucket.org/
│   └── atlassian/
│       └── stash/          # Bitbucket repository
└── other-host.com/
    └── owner/
        └── repo/           # Any other Git hosting service
```

With custom root (e.g., `--root ~/Documents`):
```
~/Documents/
├── github.com/
│   └── rails/
│       └── rails/
├── gitlab.com/
│   └── ...
└── ...
```

## Environment Variables

- `GIT_GOGET_ROOT` - Set default root directory (overrides git config)

## Configuration

### Git Config

You can set a default root directory using git config:

```bash
# Set global default root directory
git config user.rootDirectory ~/myprojects

# Set repository-specific root directory
git config --local user.rootDirectory ~/work-projects

# Unset the configuration
git config --unset user.rootDirectory
```

### Environment Variable

Set the `GIT_GOGET_ROOT` environment variable for temporary or session-based configuration:

```bash
# Set for current session
export GIT_GOGET_ROOT=~/workspace

# Set for single command
GIT_GOGET_ROOT=~/temp git goget https://github.com/example/repo
```

## How it works

`git-goget` automatically:

1. Determines the root directory based on priority (--root > GIT_GOGET_ROOT > git config > ~/src)
2. Parses the Git URL to extract host, owner and repository name
3. Creates the directory structure `<root>/<host>/owner/repository` if it doesn't exist
4. Clones the repository to the target directory (silent operation)
5. If the directory already exists and contains a git repository, it runs `git pull` to update it (silent operation)

The tool operates completely silently unless there are errors, making it ideal for scripts and automation.

## Supported Git hosting services

- **GitHub** (github.com)
- **GitLab** (gitlab.com)
- **Bitbucket** (bitbucket.org)
- **Any other Git hosting service** that supports standard Git protocols

## Supported URL formats

- **HTTPS**: `https://host.com/owner/repo` or `https://host.com/owner/repo.git`
- **SSH**: `git@host.com:owner/repo.git`

Examples:
- `https://github.com/rails/rails`
- `https://gitlab.com/gitlab-org/gitlab.git`
- `git@bitbucket.org:atlassian/stash.git`

## Testing

The project includes comprehensive test coverage using Bats (Bash Automated Testing System):

```bash
# Run tests locally (requires Bats installation)
bats test/git-goget.bats

# Install Bats on macOS
brew install bats-core

# Install Bats on Ubuntu/Debian
sudo apt-get install bats
```

### Continuous Integration

Tests are automatically run on GitHub Actions for all pushes and pull requests to the main branch.

## License

[MIT](../../LICENSE)
