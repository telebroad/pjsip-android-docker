#!/bin/bash -e

ANDROID_TARGET_API=$1
TARGET_ABI=$2
GCC_VERSION=$3  # Not used, included for logging or future use.

OUTPUT_PATH=/pjsip/opus/opus_${TARGET_ABI}
OPUS_TMP_FOLDER=/tmp/opus_${TARGET_ABI}

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-OPUS-BUILD:: TARGET_ABI = $TARGET_ABI, API = $ANDROID_TARGET_API" \
    | tee -a /pjsip/build_pjsip.log

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "ANDROID_NDK_ROOT is not set. Please set it before running this script." | tee -a /pjsip/build_pjsip.log
    exit 1
fi

# Ensure output directory and temporary build directory exist
mkdir -p ${OUTPUT_PATH}
mkdir -p ${OPUS_TMP_FOLDER}

# Copy Opus sources to a temporary build folder
cp -r ${OPUS_SOURCES_PATH}/* ${OPUS_TMP_FOLDER}
cd ${OPUS_TMP_FOLDER}

TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64
export PATH=$TOOLCHAIN/bin:$PATH

# Determine HOST and ARCH_PREFIX based on TARGET_ABI
if [ "$TARGET_ABI" == "armeabi-v7a" ]; then
    HOST=arm-linux-androideabi
    ARCH_PREFIX=armv7a-linux-androideabi
    export CC=${ARCH_PREFIX}${ANDROID_TARGET_API}-clang
    export CXX=${ARCH_PREFIX}${ANDROID_TARGET_API}-clang++
    export AR=${ARCH_PREFIX}-ar
    export LD=${ARCH_PREFIX}-ld
    export STRIP=${ARCH_PREFIX}-strip
elif [ "$TARGET_ABI" == "arm64-v8a" ]; then
    HOST=aarch64-linux-android
    ARCH_PREFIX=aarch64-linux-android
    export CC=${ARCH_PREFIX}${ANDROID_TARGET_API}-clang
    export CXX=${ARCH_PREFIX}${ANDROID_TARGET_API}-clang++
    export AR=${ARCH_PREFIX}-ar
    export LD=${ARCH_PREFIX}-ld
    export STRIP=${ARCH_PREFIX}-strip
elif [ "$TARGET_ABI" == "x86_64" ]; then
    HOST=x86_64-linux-android
    ARCH_PREFIX=x86_64-linux-android
    export CC=${ARCH_PREFIX}${ANDROID_TARGET_API}-clang
    export CXX=${ARCH_PREFIX}${ANDROID_TARGET_API}-clang++
    export AR=${ARCH_PREFIX}-ar
    export LD=${ARCH_PREFIX}-ld
    export STRIP=${ARCH_PREFIX}-strip
else
    echo "Unsupported target ABI: $TARGET_ABI" | tee -a /pjsip/build_pjsip.log
    exit 1
fi

export CFLAGS="-fPIC"
export LDFLAGS=""

echo "Configuring Opus for ${TARGET_ABI} with --host=${HOST} and --build=x86_64-pc-linux-gnu ..." | tee -a /pjsip/build_pjsip.log
if ! ./configure \
    --build=x86_64-pc-linux-gnu \
    --host=${HOST} \
    --prefix=/usr/local \
    --enable-static \
    --enable-shared \
    --disable-maintainer-mode \
    | tee -a /pjsip/build_pjsip.log; then
    echo "*** Configuring OPUS failed" | tee -a /pjsip/build_pjsip.log
    exit 1
fi

echo "Building Opus ..." | tee -a /pjsip/build_pjsip.log
if ! make -j$(nproc) V=1 | tee -a /pjsip/build_pjsip.log; then
    echo "*** Building OPUS failed" | tee -a /pjsip/build_pjsip.log
    exit 1
fi

# Check if libopus was built before install
echo "Checking if libopus was built before install:" | tee -a /pjsip/build_pjsip.log
find . -name "libopus*" | tee -a /pjsip/build_pjsip.log || echo "No libopus files found pre-install." | tee -a /pjsip/build_pjsip.log

# Install with DESTDIR to force installation into OUTPUT_PATH
echo "Installing Opus with DESTDIR=${OUTPUT_PATH} ..." | tee -a /pjsip/build_pjsip.log
if ! make DESTDIR=${OUTPUT_PATH} install V=1 | tee -a /pjsip/build_pjsip.log; then
    echo "*** Installing OPUS failed" | tee -a /pjsip/build_pjsip.log
    exit 1
fi

echo "Opus build completed! Check output libraries in ${OUTPUT_PATH}" | tee -a /pjsip/build_pjsip.log

echo "Inspecting installed Opus files under ${OUTPUT_PATH}:" | tee -a /pjsip/build_pjsip.log
find ${OUTPUT_PATH} -print | tee -a /pjsip/build_pjsip.log

# Cleanup build sources
rm -rf ${OPUS_TMP_FOLDER}

# Because we used DESTDIR, the real prefix inside might be /usr/local
# For example, you might find headers in ${OUTPUT_PATH}/usr/local/include/opus
# and libs in ${OUTPUT_PATH}/usr/local/lib

echo "Listing Opus headers in ${OUTPUT_PATH} (searching recursively):" | tee -a /pjsip/build_pjsip.log
find ${OUTPUT_PATH} -name opus.h | tee -a /pjsip/build_pjsip.log || echo "No opus.h found." | tee -a /pjsip/build_pjsip.log

echo "Listing Opus libraries in ${OUTPUT_PATH} (searching recursively):" | tee -a /pjsip/build_pjsip.log
find ${OUTPUT_PATH} -name "libopus*" | tee -a /pjsip/build_pjsip.log || echo "No libopus found." | tee -a /pjsip/build_pjsip.log

echo "To enable Opus in PJSIP, once you identify the actual include and lib paths, use:" | tee -a /pjsip/build_pjsip.log
echo "  --with-opus=/pjsip/opus/opus_${TARGET_ABI}" | tee -a /pjsip/build_pjsip.log
echo "Set CFLAGS and LDFLAGS accordingly after locating the actual directories:" | tee -a /pjsip/build_pjsip.log
echo "  CFLAGS=\"-I/pjsip/opus/opus_${TARGET_ABI}/usr/local/include\" LDFLAGS=\"-L/pjsip/opus/opus_${TARGET_ABI}/usr/local/lib\"" | tee -a /pjsip/build_pjsip.log

# Also show prefix from config.log if available
echo "Checking prefix settings in config.log (if available):" | tee -a /pjsip/build_pjsip.log
if [ -f config.log ]; then
    grep prefix config.log | tee -a /pjsip/build_pjsip.log
fi
