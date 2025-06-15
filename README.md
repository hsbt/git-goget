# git-goget

A command-line tool to clone Git repositories to a structured directory layout.

## Overview

`git-goget` is a command-line tool that clones Git repositories to a structured directory layout under a configurable root directory. It supports various Git hosting services including GitHub, GitLab, Bitbucket, and others, following the pattern used by Go's workspace organization.

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

Enable shell completion:

```bash
source <(git goget completion)
```

### Examples

```bash
# Clone Rails repository to ~/src/github.com/rails/rails (default)
git goget https://github.com/rails/rails

# Clone GitLab project to ~/src/gitlab.com/gitlab-org/gitlab
git goget https://gitlab.com/gitlab-org/gitlab

# Clone Bitbucket repository to ~/src/bitbucket.org/atlassian/stash
git goget https://bitbucket.org/atlassian/stash

# Clone to custom root directory
git goget --root ~/Documents https://github.com/rails/rails

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

- `GOGET_DEBUG=1` - Enable debug output

## How it works

`git-goget` automatically:

1. Parses the Git URL to extract host, owner and repository name
2. Creates the directory structure `<root>/<host>/owner/repository` if it doesn't exist
3. Clones the repository to the target directory
4. If the directory already exists and contains a git repository, it runs `git pull` to update it

The default root directory is `~/src`, but you can specify a custom root with the `--root` option.

## Supported Git hosting services

- **GitHub** (github.com)
- **GitLab** (gitlab.com)
- **Bitbucket** (bitbucket.org)
- **Any other Git hosting service** that supports standard Git protocols

## Supported URL formats

- **HTTPS**: `https://host.com/owner/repo` or `https://host.com/owner/repo.git`
- **SSH**: `git@host.com:owner/repo.git`
- **Simplified**: `host.com/owner/repo`

Examples:
- `https://github.com/rails/rails`
- `https://gitlab.com/gitlab-org/gitlab.git`
- `git@bitbucket.org:atlassian/stash.git`
- `github.com/rails/rails`

## License

[MIT](../../LICENSE)
