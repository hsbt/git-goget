#!/usr/bin/env bats

SCRIPT_PATH="$BATS_TEST_DIRNAME/../git-goget"

setup() {
  # Create a temporary directory for tests
  export TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_HOME="$TEST_TEMP_DIR/home"
  export HOME="$TEST_HOME"
  mkdir -p "$TEST_HOME"
  
  # Clear git-goget environment variables to avoid interference
  unset GIT_GOGET_ROOT
  
  # Set up isolated git config environment
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig"
  touch "$GIT_CONFIG_GLOBAL"
  
  # Create a mock bin directory
  export MOCK_BIN_DIR="$TEST_TEMP_DIR/bin"
  mkdir -p "$MOCK_BIN_DIR"
  
  # Create a mock git script
  cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
  url="$2"
  dest="$3"
  mkdir -p "$dest"
  cd "$dest"
  /usr/bin/git init .
  /usr/bin/git config user.name "Test User"
  /usr/bin/git config user.email "test@example.com"
  echo "Mock repository" > README.md
  /usr/bin/git add README.md
  /usr/bin/git commit -m "Initial commit"
  echo "Cloning '$url'..."
elif [[ "$1" == "pull" ]]; then
  echo "Already up to date."
elif [[ "$1" == "config" ]]; then
  # Pass through all git config commands to real git
  /usr/bin/git "$@"
else
  /usr/bin/git "$@"
fi
EOF
  chmod +x "$MOCK_BIN_DIR/git"
  
  # Add mock bin to PATH
  export PATH="$MOCK_BIN_DIR:$PATH"
}

teardown() {
  # Clean up git config
  git config --unset user.rootDirectory 2>/dev/null || true
  
  # Clean up the test directory
  rm -rf "$TEST_TEMP_DIR"
}

@test "version command shows version number" {
  run "$SCRIPT_PATH" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^git-goget\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "help command shows usage information" {
  run "$SCRIPT_PATH" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Clone Git repositories to a structured directory layout" ]]
}

@test "clones repository with https URL" {
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  
  # Debug: show script output and exit status
  echo "# Script exit status: $status" >&3
  echo "# Script output: $output" >&3
  echo "# HOME: $HOME" >&3
  echo "# Contents of HOME:" >&3
  ls -la "$HOME" >&3 || echo "# HOME directory doesn't exist" >&3
  echo "# Contents of $HOME/src:" >&3
  ls -la "$HOME/src" >&3 || echo "# src directory doesn't exist" >&3
  echo "# Contents of $HOME/src/github.com:" >&3
  ls -la "$HOME/src/github.com" >&3 || echo "# github.com directory doesn't exist" >&3
  
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/github.com/rails/rails" ]
  [ -f "$HOME/src/github.com/rails/rails/README.md" ]
}

@test "clones repository with ssh URL" {
  run "$SCRIPT_PATH" "git@github.com:rails/rails.git"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/github.com/rails/rails" ]
}

@test "clones GitLab repository" {
  run "$SCRIPT_PATH" "https://gitlab.com/gitlab-org/gitlab"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/gitlab.com/gitlab-org/gitlab" ]
  [ -f "$HOME/src/gitlab.com/gitlab-org/gitlab/README.md" ]
}

@test "clones Bitbucket repository" {
  run "$SCRIPT_PATH" "https://bitbucket.org/atlassian/stash"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/bitbucket.org/atlassian/stash" ]
  [ -f "$HOME/src/bitbucket.org/atlassian/stash/README.md" ]
}

@test "updates existing repository" {
  # First clone
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Second clone should update
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
}

@test "handles invalid URL format" {
  run "$SCRIPT_PATH" "invalid-url"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Invalid Git URL format" ]]
}

@test "creates src directory structure" {
  run "$SCRIPT_PATH" "https://github.com/hsbt/test"
  [ "$status" -eq 0 ]
  
  # Check directory structure
  [ -d "$HOME/src" ]
  [ -d "$HOME/src/github.com" ]
  [ -d "$HOME/src/github.com/hsbt" ]
  [ -d "$HOME/src/github.com/hsbt/test" ]
}

@test "creates directory structure for different hosts" {
  run "$SCRIPT_PATH" "https://gitlab.com/hsbt/test"
  [ "$status" -eq 0 ]
  
  # Check GitLab directory structure
  [ -d "$HOME/src" ]
  [ -d "$HOME/src/gitlab.com" ]
  [ -d "$HOME/src/gitlab.com/hsbt" ]
  [ -d "$HOME/src/gitlab.com/hsbt/test" ]
}

@test "handles repository name with special characters" {
  run "$SCRIPT_PATH" "https://github.com/rails/rails.git"
  [ "$status" -eq 0 ]
  [ -d "$HOME/src/github.com/rails/rails" ]
}

@test "clones repository with --root option" {
  run "$SCRIPT_PATH" --root "$TEST_HOME/custom" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created in custom location
  [ -d "$TEST_HOME/custom/github.com/rails/rails" ]
  [ -f "$TEST_HOME/custom/github.com/rails/rails/README.md" ]
}

@test "updates existing repository with --root option" {
  # First clone
  run "$SCRIPT_PATH" --root "$TEST_HOME/custom" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Second clone should update
  run "$SCRIPT_PATH" --root "$TEST_HOME/custom" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
}

@test "shows error when no argument provided" {
  run "$SCRIPT_PATH"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Clone Git repositories to a structured directory layout" ]]
}

@test "uses git config user.rootDirectory when set" {
  # Set git config user.rootDirectory
  git config user.rootDirectory "$TEST_HOME/git-config-root"
  
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created in git config location
  [ -d "$TEST_HOME/git-config-root/github.com/rails/rails" ]
  [ -f "$TEST_HOME/git-config-root/github.com/rails/rails/README.md" ]
}

@test "--root option overrides git config user.rootDirectory" {
  # Set git config user.rootDirectory
  git config user.rootDirectory "$TEST_HOME/git-config-root"
  
  run "$SCRIPT_PATH" --root "$TEST_HOME/explicit-root" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created in explicit root location
  [ -d "$TEST_HOME/explicit-root/github.com/rails/rails" ]
  [ -f "$TEST_HOME/explicit-root/github.com/rails/rails/README.md" ]
  
  # Git config location should not be used
  [ ! -d "$TEST_HOME/git-config-root/github.com/rails/rails" ]
}

@test "falls back to ~/src when no git config user.rootDirectory and no --root" {
  # Ensure no git config user.rootDirectory is set
  git config --unset user.rootDirectory 2>/dev/null || true
  
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created in default location
  [ -d "$HOME/src/github.com/rails/rails" ]
  [ -f "$HOME/src/github.com/rails/rails/README.md" ]
}

@test "uses GIT_GOGET_ROOT environment variable when set" {
  # Set GIT_GOGET_ROOT environment variable
  export GIT_GOGET_ROOT="$TEST_HOME/env-root"
  
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that the directory structure was created in environment variable location
  [ -d "$TEST_HOME/env-root/github.com/rails/rails" ]
  [ -f "$TEST_HOME/env-root/github.com/rails/rails/README.md" ]
  
  unset GIT_GOGET_ROOT
}

@test "GIT_GOGET_ROOT overrides git config user.rootDirectory" {
  # Set both environment variable and git config
  export GIT_GOGET_ROOT="$TEST_HOME/env-root"
  git config user.rootDirectory "$TEST_HOME/git-config-root"
  
  run "$SCRIPT_PATH" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that environment variable takes priority
  [ -d "$TEST_HOME/env-root/github.com/rails/rails" ]
  [ -f "$TEST_HOME/env-root/github.com/rails/rails/README.md" ]
  
  # Git config location should not be used
  [ ! -d "$TEST_HOME/git-config-root/github.com/rails/rails" ]
  
  unset GIT_GOGET_ROOT
}

@test "--root option overrides GIT_GOGET_ROOT environment variable" {
  # Set GIT_GOGET_ROOT environment variable
  export GIT_GOGET_ROOT="$TEST_HOME/env-root"
  
  run "$SCRIPT_PATH" --root "$TEST_HOME/explicit-root" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  
  # Check that --root option takes highest priority
  [ -d "$TEST_HOME/explicit-root/github.com/rails/rails" ]
  [ -f "$TEST_HOME/explicit-root/github.com/rails/rails/README.md" ]
  
  # Environment variable location should not be used
  [ ! -d "$TEST_HOME/env-root/github.com/rails/rails" ]
  
  unset GIT_GOGET_ROOT
}
