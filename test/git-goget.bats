#!/usr/bin/env bats

SCRIPT_PATH="$BATS_TEST_DIRNAME/../git-goget"

setup() {
  # Create a temporary directory for tests
  export TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_HOME="$TEST_TEMP_DIR/home"
  export HOME="$TEST_HOME"
  mkdir -p "$TEST_HOME"
  
  # Create a temporary git repository to simulate cloning
  export TEST_REPO_DIR="$TEST_TEMP_DIR/test-repo"
  mkdir -p "$TEST_REPO_DIR"
  cd "$TEST_REPO_DIR"
  git init --bare .
  
  # Mock the git clone command to avoid actual network calls
  function git() {
    if [[ "$1" == "clone" ]]; then
      local url="$2"
      local dest="$3"
      mkdir -p "$dest"
      cd "$dest"
      command git init .
      command git config user.name "Test User"
      command git config user.email "test@example.com"
      echo "Mock repository" > README.md
      command git add README.md
      command git commit -m "Initial commit"
      echo "Cloning '$url'..."
    elif [[ "$1" == "pull" ]]; then
      echo "Already up to date."
    else
      command git "$@"
    fi
  }
  export -f git
}

teardown() {
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
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cloned repository to $HOME/src/github.com/rails/rails" ]]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/github.com/rails/rails" ]
  [ -f "$HOME/src/github.com/rails/rails/README.md" ]
}

@test "clones repository with ssh URL" {
  run "$SCRIPT_PATH" "git@github.com:rails/rails.git"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cloned repository to $HOME/src/github.com/rails/rails" ]]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/github.com/rails/rails" ]
}

@test "clones GitLab repository" {
  run "$SCRIPT_PATH" "https://gitlab.com/gitlab-org/gitlab"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cloned repository to $HOME/src/gitlab.com/gitlab-org/gitlab" ]]
  
  # Check that the directory structure was created
  [ -d "$HOME/src/gitlab.com/gitlab-org/gitlab" ]
  [ -f "$HOME/src/gitlab.com/gitlab-org/gitlab/README.md" ]
}

@test "clones Bitbucket repository" {
  run "$SCRIPT_PATH" "https://bitbucket.org/atlassian/stash"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cloned repository to $HOME/src/bitbucket.org/atlassian/stash" ]]
  
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
  [[ "$output" =~ "Directory $HOME/src/github.com/rails/rails already exists. Updating repository..." ]]
  [[ "$output" =~ "Updated repository in $HOME/src/github.com/rails/rails" ]]
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
  [[ "$output" =~ "Cloned repository to $TEST_HOME/custom/github.com/rails/rails" ]]
  
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
  [[ "$output" =~ "Directory $TEST_HOME/custom/github.com/rails/rails already exists. Updating repository..." ]]
  [[ "$output" =~ "Updated repository in $TEST_HOME/custom/github.com/rails/rails" ]]
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
  [[ "$output" =~ "Cloned repository to $TEST_HOME/git-config-root/github.com/rails/rails" ]]
  
  # Check that the directory structure was created in git config location
  [ -d "$TEST_HOME/git-config-root/github.com/rails/rails" ]
  [ -f "$TEST_HOME/git-config-root/github.com/rails/rails/README.md" ]
}

@test "--root option overrides git config user.rootDirectory" {
  # Set git config user.rootDirectory
  git config user.rootDirectory "$TEST_HOME/git-config-root"
  
  run "$SCRIPT_PATH" --root "$TEST_HOME/explicit-root" "https://github.com/rails/rails"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cloned repository to $TEST_HOME/explicit-root/github.com/rails/rails" ]]
  
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
  [[ "$output" =~ "Cloned repository to $HOME/src/github.com/rails/rails" ]]
  
  # Check that the directory structure was created in default location
  [ -d "$HOME/src/github.com/rails/rails" ]
  [ -f "$HOME/src/github.com/rails/rails/README.md" ]
}
