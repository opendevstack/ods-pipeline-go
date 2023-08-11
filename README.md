# ods-pipeline-go

Tekton task for use with [ODS Pipeline](https://github.com/opendevstack/ods-pipeline) to build Go applications.

## Usage

```yaml
tasks:
- name: build
  taskRef:
    resolver: git
    params:
    - { name: url, value: https://github.com/bix-digital/ods-pipeline-v1-go-build.git }
    - { name: revision, value: latest }
    - { name: pathInRepo, value: tasks/ods-pipeline-v1-go-build.yaml }
    workspaces:
    - { name: source, workspace: shared-workspace }
```

See the [documentation](https://github.com/BIX-Digital/ods-pipeline-go/blob/main/docs/ods-pipeline-v1-go-build.adoc) for details and available parameters.

## About this repository

`docs` and `tasks` are generated directories from recipes located in `build`. See the `Makefile` target for how everything fits together.
