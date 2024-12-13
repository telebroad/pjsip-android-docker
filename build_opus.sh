#!/bin/bash -ex

ANDROID_TARGET_API=$1
TARGET_ABI=$2
GCC_VERSION=$3  # Not used, included for logging or future use.

OUTPUT_PATH=/pjsip/opus/opus_${TARGET_ABI}

# 1. First, set up environment variables in your .bashrc or .zshrc
export ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
export VCPKG_ROOT=${OUTPUT_PATH}
export OPUS_OUTPUT_PATH="${OUTPUT_PATH}/installed"

# 2. Create a vcpkg.json manifest file
cat > vcpkg.json << EOF
{
  "name": "my-opus-project",
  "version": "1.0.0",
  "dependencies": [
    "opus"
  ]
}
EOF

# 3. Build Opus for all Android architectures
${VCPKG_ROOT}/vcpkg install opus:x86-android
${VCPKG_ROOT}/vcpkg install opus:x64-android
${VCPKG_ROOT}/vcpkg install opus:arm-android
${VCPKG_ROOT}/vcpkg install opus:arm64-android


