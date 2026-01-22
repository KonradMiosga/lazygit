package git_commands

import (
	"testing"

	"github.com/jesseduffield/lazygit/pkg/commands/oscommands"
	"github.com/stretchr/testify/assert"
)

func TestTagCommands_CreateLightweightObj(t *testing.T) {
	type scenario struct {
		testName        string
		tagName         string
		ref             string
		force           bool
		expectedCmdArgs []string
	}

	scenarios := []scenario{
		{
			testName:        "create simple lightweight tag on HEAD",
			tagName:         "v1.0.0",
			ref:             "",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "--", "v1.0.0"},
		},
		{
			testName:        "create lightweight tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "abc123",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "--", "v1.0.0", "abc123"},
		},
		{
			testName:        "create lightweight tag with force flag",
			tagName:         "v1.0.0",
			ref:             "",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "--force", "--", "v1.0.0"},
		},
		{
			testName:        "create forced lightweight tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "def456",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "--force", "--", "v1.0.0", "def456"},
		},
	}

	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t)
			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			cmdObj := tagCommands.CreateLightweightObj(s.tagName, s.ref, s.force)

			assert.Equal(t, s.expectedCmdArgs, cmdObj.Args())
		})
	}
}

func TestTagCommands_CreateAnnotatedObj(t *testing.T) {
	type scenario struct {
		testName        string
		tagName         string
		ref             string
		msg             string
		force           bool
		expectedCmdArgs []string
	}

	scenarios := []scenario{
		{
			testName:        "create annotated tag on HEAD",
			tagName:         "v1.0.0",
			ref:             "",
			msg:             "Release version 1.0.0",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "-m", "Release version 1.0.0"},
		},
		{
			testName:        "create annotated tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "abc123",
			msg:             "Major release",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "abc123", "-m", "Major release"},
		},
		{
			testName:        "create forced annotated tag",
			tagName:         "v1.0.0",
			ref:             "",
			msg:             "Latest stable",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "--force", "-m", "Latest stable"},
		},
		{
			testName:        "create forced annotated tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "xyz789",
			msg:             "Beta version",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "--force", "xyz789", "-m", "Beta version"},
		},
	}

	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t)
			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			cmdObj := tagCommands.CreateAnnotatedObj(s.tagName, s.ref, s.msg, s.force)

			assert.Equal(t, s.expectedCmdArgs, cmdObj.Args())
		})
	}
}

func TestTagCommands_LocalDelete(t *testing.T) {
	runner := oscommands.NewFakeRunner(t).
		ExpectGitArgs([]string{"tag", "-d", "v1.0.0"}, "", nil)

	gitCommon := buildGitCommon(commonDeps{runner: runner})
	tagCommands := NewTagCommands(gitCommon)

	err := tagCommands.LocalDelete("v1.0.0")

	assert.NoError(t, err)
	runner.CheckForMissingCalls()
}

func TestTagCommands_IsTagAnnotated(t *testing.T) {
	type scenario struct {
		testName       string
		tagName        string
		gitOutput      string
		gitError       error
		expectedResult bool
		expectedError  error
	}

	// Boundary value analysis for Git output parsing:
	// - "tag\n" (exact match for annotated tag)
	// - "commit\n" (exact match for lightweight tag)
	// - "  tag  \n" (whitespace edge case)

	scenarios := []scenario{
		{
			testName:       "tag is annotated",
			tagName:        "v1.0.0",
			gitOutput:      "tag\n",
			gitError:       nil,
			expectedResult: true,
			expectedError:  nil,
		},
		{
			testName:       "tag is lightweight",
			tagName:        "v1.0.0",
			gitOutput:      "commit\n",
			gitError:       nil,
			expectedResult: false,
			expectedError:  nil,
		},
		{
			testName:       "tag with extra whitespace",
			tagName:        "v1.0.0",
			gitOutput:      "  tag  \n",
			gitError:       nil,
			expectedResult: true,
			expectedError:  nil,
		},
	}

	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t).
				ExpectGitArgs([]string{"cat-file", "-t", "refs/tags/" + s.tagName}, s.gitOutput, s.gitError)

			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			result, err := tagCommands.IsTagAnnotated(s.tagName)

			assert.Equal(t, s.expectedResult, result)
			if s.expectedError != nil {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
			runner.CheckForMissingCalls()
		})
	}
}
