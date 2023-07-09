#!/bin/bash
set -eu

copyLintReport() {
  cat golangci-lint-report.txt
  mkdir -p "${tmp_artifacts_dir}/lint-reports"
  cp golangci-lint-report.txt "${tmp_artifacts_dir}/lint-reports/${artifact_prefix}report.txt"
}

enable_cgo="false"
go_os=""
go_arch=""
output_dir="docker"
working_dir="."
artifact_prefix=""
pre_test_script=""
debug="${debug:-false}"

while [[ "$#" -gt 0 ]]; do
    case $1 in

    --working-dir) working_dir="$2"; shift;;
    --working-dir=*) working_dir="${1#*=}";;

    --enable-cgo) enable_cgo="$2"; shift;;
    --enable-cgo=*) enable_cgo="${1#*=}";;

    --go-os) go_os="$2"; shift;;
    --go-os=*) go_os="${1#*=}";;

    --go-arch) go_arch="$2"; shift;;
    --go-arch=*) go_arch="${1#*=}";;

    --output-dir) output_dir="$2"; shift;;
    --output-dir=*) output_dir="${1#*=}";;

    --pre-test-script) pre_test_script="$2"; shift;;
    --pre-test-script=*) pre_test_script="${1#*=}";;

    --debug) debug="$2"; shift;;
    --debug=*) debug="${1#*=}";;

  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

if [ "${debug}" == "true" ]; then
  set -x
fi

root_dir=$(pwd)
tmp_artifacts_dir="${root_dir}/.ods/tmp-artifacts"
# tmp_artifacts_dir enables keeping artifacts created by this build 
# separate from other builds in the same repo to facilitate caching.
rm -rf "${tmp_artifacts_dir}"
if [ "${working_dir}" != "." ]; then
  cd "${working_dir}"
  artifact_prefix="${working_dir/\//-}-"
fi

echo "Working on Go module in $(pwd) ..."

go version
if [ "${enable_cgo}" = "false" ]; then
  export CGO_ENABLED=0
fi
if [ -n "${go_os}" ]; then
  export GOOS="${go_os}"
fi
if [ -n "${go_arch}" ]; then
  export GOARCH="${go_arch}"
fi
export GOMODCACHE="$root_dir/.ods-cache/deps/gomod"
echo INFO: Using gomodule cache on repo pvc
echo GOMODCACHE="$GOMODCACHE"
df -h "$root_dir"

echo "Checking format ..."
# shellcheck disable=SC2046
unformatted=$(go fmt $(go list ./...))
if [ -n "${unformatted}" ]; then
  echo "Unformatted files:"
  echo "${unformatted}"
  echo "All files need to be gofmt'd. Please run: gofmt -w ."
  exit 1
fi

echo "Linting ..."
golangci-lint version
set +e
rm golangci-lint-report.txt &>/dev/null
golangci-lint run > golangci-lint-report.txt
exitcode=$?
set -e
if [ $exitcode == 0 ]; then
  echo "OK" > golangci-lint-report.txt
  copyLintReport
else
  copyLintReport
  exit $exitcode
fi

echo "Testing ..."
if [ -n "${pre_test_script}" ]; then
  echo "Executing pre-test script ..."
  ./"${pre_test_script}"
fi
GOPKGS=$(go list ./... | grep -v /vendor)
set +e
rm coverage.out test-results.txt report.xml &>/dev/null
go test -v -coverprofile=coverage.out "$GOPKGS" > test-results.txt 2>&1
exitcode=$?
set -e
df -h "$root_dir"
if [ -f test-results.txt ]; then
    cat test-results.txt
    go-junit-report < test-results.txt > report.xml
    mkdir -p "${tmp_artifacts_dir}/xunit-reports"
    cp report.xml "${tmp_artifacts_dir}/xunit-reports/${artifact_prefix}report.xml"
else
  echo "No test results found"
  exit 1
fi
if [ -f coverage.out ]; then
    mkdir -p "${tmp_artifacts_dir}/code-coverage"
    cp coverage.out "${tmp_artifacts_dir}/code-coverage/${artifact_prefix}coverage.out"
else
  echo "No code coverage found"
  exit 1
fi
if [ $exitcode != 0 ]; then
  exit $exitcode
fi
echo "Building ..."
go build -gcflags "all=-trimpath=$(pwd)" -o "${output_dir}/app"
