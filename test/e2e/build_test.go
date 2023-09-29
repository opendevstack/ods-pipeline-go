package e2e

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"

	ott "github.com/opendevstack/ods-pipeline/pkg/odstasktest"
	"github.com/opendevstack/ods-pipeline/pkg/pipelinectxt"
	ttr "github.com/opendevstack/ods-pipeline/pkg/tektontaskrun"
	cp "github.com/otiai10/copy"
	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1beta1"
)

func TestBuildGoTask(t *testing.T) {
	if err := runTask(
		ttr.WithStringParams(map[string]string{
			"go-os":       runtime.GOOS,
			"go-arch":     runtime.GOARCH,
			"cache-build": "false",
		}),
		withGoWorkspace(t, "go-sample-app"),
		ttr.AfterRun(func(config *ttr.TaskRunConfig, run *tekton.TaskRun, logs bytes.Buffer) {
			wd := config.WorkspaceConfigs["source"].Dir
			cmd := exec.Command(wd + "/docker/app")
			b, err := cmd.Output()
			if err != nil {
				t.Fatal(err)
			}
			goProverb := "Don't communicate by sharing memory, share memory by communicating."
			if string(b) != goProverb {
				t.Fatalf("Got: %+v, want: %+v.", string(b), goProverb)
			}

			ott.AssertFilesExist(t, wd,
				"docker/Dockerfile",
				"docker/app",
				filepath.Join(pipelinectxt.LintReportsPath, "report.txt"),
				filepath.Join(pipelinectxt.XUnitReportsPath, "report.xml"),
				filepath.Join(pipelinectxt.CodeCoveragesPath, "coverage.out"),
			)
		}),
	); err != nil {
		t.Fatal(err)
	}
}

func TestBuildGoTaskLintError(t *testing.T) {
	if err := runTask(
		ttr.WithStringParams(
			map[string]string{"cache-build": "false"},
		),
		withGoWorkspace(t, "go-sample-app-lint-error"),
		ttr.ExpectFailure(),
		ttr.AfterRun(func(config *ttr.TaskRunConfig, run *tekton.TaskRun, logs bytes.Buffer) {
			ott.AssertFileContent(t,
				config.WorkspaceConfigs["source"].Dir,
				filepath.Join(pipelinectxt.LintReportsPath, "report.txt"),
				"main.go:6:2: printf: fmt.Printf format %s reads arg #1, but call has 0 args (govet)\n\tfmt.Printf(\"Hello World %s\") // lint error on purpose to generate lint report\n\t^",
			)
		}),
	); err != nil {
		t.Fatal(err)
	}
}

func TestBuildGoSubdirectory(t *testing.T) {
	subdir := "go-src"
	if err := runTask(
		ttr.WithStringParams(map[string]string{
			"cache-build": "false",
			"working-dir": subdir,
		}),
		withGoWorkspace(t, "hello-world-app", func(c *ttr.WorkspaceConfig) error {
			createAppInSubDirectory(t, c.Dir, subdir, "go-sample-app")
			return nil
		}),
		ttr.ExpectFailure(),
		ttr.AfterRun(func(config *ttr.TaskRunConfig, run *tekton.TaskRun, logs bytes.Buffer) {
			ott.AssertFilesExist(
				t, config.WorkspaceConfigs["source"].Dir,
				fmt.Sprintf("%s/docker/Dockerfile", subdir),
				fmt.Sprintf("%s/docker/app", subdir),
				filepath.Join(pipelinectxt.LintReportsPath, fmt.Sprintf("%s-report.txt", subdir)),
				filepath.Join(pipelinectxt.XUnitReportsPath, fmt.Sprintf("%s-report.xml", subdir)),
				filepath.Join(pipelinectxt.CodeCoveragesPath, fmt.Sprintf("%s-coverage.out", subdir)),
			)
		}),
	); err != nil {
		t.Fatal(err)
	}
}

func createAppInSubDirectory(t *testing.T, wsDir string, subdir string, sampleApp string) {
	err := os.MkdirAll(filepath.Join(wsDir, subdir), 0755)
	if err != nil {
		t.Fatal(err)
	}
	err = cp.Copy(
		filepath.Join("../../test/testdata/workspaces", sampleApp),
		filepath.Join(wsDir, subdir),
	)
	if err != nil {
		t.Fatal(err)
	}
}

func withGoWorkspace(t *testing.T, dir string, opts ...ttr.WorkspaceOpt) ttr.TaskRunOpt {
	return ott.WithGitSourceWorkspace(
		t, filepath.Join("../testdata/workspaces", dir), namespaceConfig.Name,
		append([]ttr.WorkspaceOpt{cleanModcacheOpt(t, dir)}, opts...)...,
	)
}

func cleanModcacheOpt(t *testing.T, dir string) ttr.WorkspaceOpt {
	return func(c *ttr.WorkspaceConfig) error {
		origCleanup := c.Cleanup
		c.Cleanup = func() {
			cleanModcache(t, c.Dir)
			origCleanup()
		}
		return nil
	}
}

func cleanModcache(t *testing.T, workspace string) {
	var stderr bytes.Buffer
	cmd := exec.Command("go", "clean", "-modcache")
	cmd.Env = append(cmd.Env, fmt.Sprintf("GOMODCACHE=%s/%s", workspace, ".ods-cache/deps/gomod"))
	cmd.Stdout = io.Discard
	if err := cmd.Run(); err != nil {
		t.Errorf("could not clean up modcache: %s, stderr: %s", err, stderr.String())
	}
}
