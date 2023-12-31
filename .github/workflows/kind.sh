#!/bin/bash
set -o errexit

echo "which:"
which kind
echo "command"
command -v kind
echo "bash"
bash --version
echo "check"
if ! command -v kind >/dev/null 2>&1; then
  echo "kind is not installed. Please see https://kind.sigs.k8s.io/"
  exit 1
fi
