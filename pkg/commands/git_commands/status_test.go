package git_commands

import (
	"testing"

	"github.com/jesseduffield/lazygit/pkg/commands/models"
	"github.com/stretchr/testify/assert"
)

func TestStatusCommands_WorkingTreeState_EmptyState(t *testing.T) {
	// Test that WorkingTreeState returns all false when not in any special state
	// Note: This test relies on not being in an actual git repository with special states
	repoPaths := &RepoPaths{
		worktreePath:       "/nonexistent",
		worktreeGitDirPath: "/nonexistent/.git",
		repoPath:           "/nonexistent",
		repoGitDirPath:     "/nonexistent/.git",
		repoName:           "test",
		isBareRepo:         false,
	}

	gitCommon := buildGitCommon(commonDeps{
		repoPaths: repoPaths,
	})
	statusCommands := NewStatusCommands(gitCommon)

	state := statusCommands.WorkingTreeState()
	
	expectedState := models.WorkingTreeState{
		Rebasing:      false,
		Merging:       false,
		CherryPicking: false,
		Reverting:     false,
	}
	
	assert.Equal(t, expectedState, state)
}

func TestStatusCommands_IsBareRepo_NonBare(t *testing.T) {
	repoPaths := &RepoPaths{
		worktreePath:       "/repo",
		worktreeGitDirPath: "/repo/.git",
		repoPath:           "/repo",
		repoGitDirPath:     "/repo/.git",
		repoName:           "test",
		isBareRepo:         false,
	}

	gitCommon := buildGitCommon(commonDeps{
		repoPaths: repoPaths,
	})
	statusCommands := NewStatusCommands(gitCommon)

	assert.False(t, statusCommands.IsBareRepo())
}

func TestStatusCommands_IsBareRepo_Bare(t *testing.T) {
	bareRepoPaths := &RepoPaths{
		worktreePath:       "",
		worktreeGitDirPath: "/bare-repo",
		repoPath:           "/bare-repo",
		repoGitDirPath:     "/bare-repo",
		repoName:           "bare-test",
		isBareRepo:         true,
	}

	gitCommon := buildGitCommon(commonDeps{
		repoPaths: bareRepoPaths,
	})
	statusCommands := NewStatusCommands(gitCommon)

	assert.True(t, statusCommands.IsBareRepo())
}
