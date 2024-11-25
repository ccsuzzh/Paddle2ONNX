#!/bin/bash

# Copyright (c) ONNX Project Contributors
#
# SPDX-License-Identifier: Apache-2.0

set -e -x

# CLI arguments
PY_VERSION=$1
PLAT=$2
SYSTEM_NAME=$3

if [[ "$SYSTEM_NAME" == "CentOS" ]]; then
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
elif [[ "$SYSTEM_NAME" == "Darwin" ]]; then
    export DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:/usr/local/lib
fi

# Compile wheels
# Need to be updated if there is a new Python Version
# declare -A python_map=( ["3.8"]="cp38-cp38" ["3.9"]="cp39-cp39" ["3.10"]="cp310-cp310" ["3.11"]="cp311-cp311" ["3.12"]="cp312-cp312")

# Map Python version to ABI tag using a case statement
case "$PY_VERSION" in
    "3.8") PY_VER="cp38-cp38" ;;
    "3.9") PY_VER="cp39-cp39" ;;
    "3.10") PY_VER="cp310-cp310" ;;
    "3.11") PY_VER="cp311-cp311" ;;
    "3.12") PY_VER="cp312-cp312" ;;
    *)
        echo "Unsupported Python version: $PY_VERSION"
        exit 1
        ;;
esac

PIP_INSTALL_COMMAND="/opt/python/${PY_VER}/bin/pip install --no-cache-dir -q"
PYTHON_COMMAND="/opt/python/${PY_VER}/bin/python"

# Check if the Python executable exists, fallback for macOS
if [[ ! -x "$PYTHON_COMMAND" ]]; then
    if [[ "$SYSTEM_NAME" == "Darwin" ]]; then
        PYTHON_COMMAND=$(find /usr/local/bin /usr/bin /opt/homebrew/bin -name "python${PY_VERSION}" -type f 2>/dev/null | head -n 1)
        if [[ -z "$PYTHON_COMMAND" ]]; then
            echo "Python $PY_VERSION not found on macOS."
            exit 1
        fi
        PIP_INSTALL_COMMAND="$PYTHON_COMMAND -m pip install --no-cache-dir -q"
    fi
fi

# Update pip and install cmake
$PIP_INSTALL_COMMAND --upgrade pip
$PIP_INSTALL_COMMAND cmake

# Build protobuf from source
if [[ "$SYSTEM_NAME" == "CentOS" ]]; then
    yum install -y wget
elif [[ "$SYSTEM_NAME" == "Darwin" ]]; then
    which wget || brew install wget
fi

source .github/workflows/scripts/download_protobuf.sh

# Build Paddle2ONNX wheels
$PYTHON_COMMAND -m build --wheel || { echo "Building wheels failed."; exit 1; }

# Bundle external shared libraries into the wheels
# find -exec does not preserve failed exit codes, so use an output file for failures
failed_wheels=$PWD/failed-wheels
rm -f "$failed_wheels"
# find . -type f -iname "*-linux*.whl" -exec sh -c "auditwheel repair '{}' -w \$(dirname '{}') --plat '${PLAT}' || { echo 'Repairing wheels failed.'; auditwheel show '{}' >> '$failed_wheels'; }" \;
if [[ "$SYSTEM_NAME" == "CentOS" ]]; then
    find . -type f -iname "*-linux*.whl" -exec sh -c \
        "auditwheel repair '{}' -w \$(dirname '{}') --plat '${PLAT}' || { echo 'Repairing wheels failed.'; auditwheel show '{}' >> '$failed_wheels'; }" \;
elif [[ "$SYSTEM_NAME" == "Darwin" ]]; then
    find . -type f -iname "*.whl" -exec sh -c \
        "delocate-wheel -w repaired_wheels '{}' || { echo 'Repairing wheels failed.'; echo '{}' >> '$failed_wheels'; }" \;
fi

if [[ -f "$failed_wheels" ]]; then
    echo "Repairing wheels failed:"
    cat failed-wheels
    exit 1
fi

ls dist/*

if [[ "$SYSTEM_NAME" == "CentOS" ]]; then
    # Remove useless *-linux*.whl; only keep manylinux*.whl
    rm -f dist/*-linux*.whl

    echo "Successfully build wheels:"
    find . -type f -iname "*manylinux*.whl"
fi