#!/bin/bash
set -o errexit

if ! command -v kind &> /dev/null; then
  echo "kind is not installed. Please see https://kind.sigs.k8s.io/"
  exit 1
fi
