# ods-pipeline-go

[![Tests](https://github.com/opendevstack/ods-pipeline-go/actions/workflows/main.yaml/badge.svg)](https://github.com/opendevstack/ods-pipeline-go/actions/workflows/main.yaml)

Tekton task for use with [ODS Pipeline](https://github.com/opendevstack/ods-pipeline) to build Go applications.

## Usage

```yaml
tasks:
- name: build
  taskRef:
    resolver: git
    params:
    - { name: url, value: https://github.com/opendevstack/ods-pipeline-go.git }
    - { name: revision, value: v0.3.0 }
    - { name: pathInRepo, value: tasks/build.yaml }
    workspaces:
    - { name: source, workspace: shared-workspace }
```

See the [documentation](https://github.com/opendevstack/ods-pipeline-go/blob/main/docs/task-build.adoc) for details and available parameters.

## About this repository

`docs` and `tasks` are generated directories from recipes located in `build`. See the `Makefile` target for how everything fits together.
