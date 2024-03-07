#!/bin/bash
set -eu

build_extra_inputs=""
build_reused_from_location_path=""
build_script="/usr/local/bin/go-build-script"
cache_build="true"
enable_cgo="false"
go_os="linux"
go_arch="amd64"
output_dir="docker"
working_dir="."
pre_test_script=""
debug="false"

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -build-extra-inputs=*) build_extra_inputs="${1#*=}";;
  -build-reused-from-location-path=*) build_reused_from_location_path="${1#*=}";;
  -build-script=*) build_script="${1#*=}";;
  -cache-build=*) cache_build="${1#*=}";;
  -debug=*) debug="${1#*=}";;
  -enable-cgo=*) enable_cgo="${1#*=}";;
  -go-os=*) go_os="${1#*=}";;
  -go-arch=*) go_arch="${1#*=}";;
  -output-dir=*) output_dir="${1#*=}";;
  -pre-test-script=*) pre_test_script="${1#*=}";;
  -working-dir=*) working_dir="${1#*=}";;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

echo -n "" > "${build_reused_from_location_path}"
cache_build_key="go-${go_os}-${go_arch}"
if copy-build-if-cached \
    --cache-build="${cache_build}" \
    --cache-build-key="${cache_build_key}" \
    --build-extra-inputs="${build_extra_inputs}" \
    --cached-outputs="${output_dir}" \
    --cache-location-used-path="${build_reused_from_location_path}" \
    --working-dir="${working_dir}" \
    --debug="${debug}" ; then
    exit 0
fi
set +e 
"${build_script}" \
    --working-dir="${working_dir}" \
    --enable-cgo="${enable_cgo}" \
    --go-os="${go_os}" \
    --go-arch="${go_arch}" \
    --pre-test-script="${pre_test_script}" \
    --output-dir="${output_dir}" \
    --debug="${debug}"
build_exit=$?
set -e
copy-artifacts --debug="${debug}"
if [ $build_exit -ne 0 ]; then
    exit $build_exit
fi
cache-build \
    --cache-build="${cache_build}" \
    --cache-build-key="${cache_build_key}" \
    --build-extra-inputs="${build_extra_inputs}" \
    --cached-outputs="${output_dir}" \
    --cache-location-used-path="${build_reused_from_location_path}" \
    --working-dir="${working_dir}" \
    --debug="${debug}"


