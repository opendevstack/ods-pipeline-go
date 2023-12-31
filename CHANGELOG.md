# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Note that changes which ONLY affect documentation or the testsuite will not be
listed in the changelog.

## [Unreleased]

## [0.3.0] - 2023-11-21

### Changed

- Update Go from 1.18 to 1.20, and `golangci-lint` and `go-junit-report` to latest versions ([#6](https://github.com/opendevstack/ods-pipeline-go/pull/6))

## [0.2.0] - 2023-10-09

### Changed

- Migrate from Tekton v1beta1 resources to v1 ([#5](https://github.com/opendevstack/ods-pipeline-go/pull/5))

## [0.1.2] - 2023-09-29

### Fixed

- The release workflow did not run properly for 0.1.1 either.

## [0.1.1] - 2023-09-29

### Fixed

- The release workflow did not work properly for 0.1.0.

## [0.1.0] - 2023-09-29

Initial version.

NOTE: This version is based on v0.13.2 of the task `ods-build-go` in the [ods-pipeline](https://github.com/opendevstack/ods-pipeline) repository.
