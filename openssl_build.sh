#!/bin/bash -e
set -x
# used https://github.com/217heidai/openssl_for_android/blob/master/openssl_build.sh

WORK_PATH=$(cd "$(dirname "$0")";pwd)
# ANDROID_NDK_PATH=${WORK_PATH}/android-ndk-r26b-linux
OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.2.0
# ANDROID_TARGET_API=$1
# ANDROID_TARGET_ABI=$2
OUTPUT_PATH=${WORK_PATH}/openssl_3.2.0_${ANDROID_TARGET_ABI}

OPENSSL_TMP_FOLDER=/tmp/openssl_${ANDROID_TARGET_ABI}
mkdir -p ${OPENSSL_TMP_FOLDER}
echo ${WORK_PATH}
echo cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}
cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}


PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:$PATH
cd ${OPENSSL_TMP_FOLDER}
./Configure android-arm64 -D__ANDROID_API__=${ANDROID_TARGET_API} -static no-asm no-shared no-tests --prefix=${OUTPUT_PATH}
mkdir -p ${OUTPUT_PATH}
make && make install

rm -rf ${OPENSSL_TMP_FOLDER}
rm -rf ${OUTPUT_PATH}/bin
rm -rf ${OUTPUT_PATH}/share
rm -rf ${OUTPUT_PATH}/ssl
rm -rf ${OUTPUT_PATH}/lib/engines*
rm -rf ${OUTPUT_PATH}/lib/pkgconfig
rm -rf ${OUTPUT_PATH}/lib/ossl-modules
echo "Build completed! Check output libraries in ${OUTPUT_PATH}"

