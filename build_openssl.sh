#!/bin/bash -e




ANDROID_TARGET_API=$1
ANDROID_TARGET_ABI=$2
OPENSSL_OUTPUT_PATH_TARGET=${WORK_PATH}/openssl_3.2.0_${ANDROID_TARGET_ABI}

OPENSSL_TMP_FOLDER=/tmp/openssl_${ANDROID_TARGET_ABI}
mkdir -p ${OPENSSL_TMP_FOLDER}
cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}

function build_library {
    mkdir -p ${OPENSSL_OUTPUT_PATH_TARGET}
    make && make install
    rm -rf ${OPENSSL_TMP_FOLDER}
    rm -rf ${OPENSSL_OUTPUT_PATH_TARGET}/bin
    rm -rf ${OPENSSL_OUTPUT_PATH_TARGET}/share
    rm -rf ${OPENSSL_OUTPUT_PATH_TARGET}/ssl
    rm -rf ${OPENSSL_OUTPUT_PATH_TARGET}/lib/engines*
    rm -rf ${OPENSSL_OUTPUT_PATH_TARGET}/lib/pkgconfig
    rm -rf ${OPENSSL_OUTPUT_PATH_TARGET}/lib/ossl-modules
    echo "Build completed! Check output libraries in ${OPENSSL_OUTPUT_PATH_TARGET}"
}

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-OPENSSL:: TARGET_ABI = $ANDROID_TARGET_ABI" \
    | tee -a /pjsip/build_pjsip.log


if [ "$ANDROID_TARGET_ABI" == "armeabi-v7a" ]
then
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:$PATH
    cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-arm -D__ANDROID_API__=${ANDROID_TARGET_API} -fPIC no-asm no-shared no-tests --prefix=${OPENSSL_OUTPUT_PATH_TARGET} \
    | tee -a /pjsip/build_pjsip.log
    build_library \
    | tee -a /pjsip/build_pjsip.log

elif [ "$ANDROID_TARGET_ABI" == "arm64-v8a" ]
then
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:$PATH
    cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-arm64 -D__ANDROID_API__=${ANDROID_TARGET_API} -fPIC no-asm no-shared no-tests --prefix=${OPENSSL_OUTPUT_PATH_TARGET} \
    | tee -a /pjsip/build_pjsip.log
    build_library \
    | tee -a /pjsip/build_pjsip.log

elif [ "$ANDROID_TARGET_ABI" == "x86" ]
then
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:$PATH
    cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-x86 -D__ANDROID_API__=${ANDROID_TARGET_API} -fPIC no-asm no-shared no-tests --prefix=${OPENSSL_OUTPUT_PATH_TARGET} \
    | tee -a /pjsip/build_pjsip.log
    build_library \
    | tee -a /pjsip/build_pjsip.log

elif [ "$ANDROID_TARGET_ABI" == "x86_64" ]
then
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:$PATH
    cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-x86_64 -D__ANDROID_API__=${ANDROID_TARGET_API} -fPIC no-asm no-shared no-tests --prefix=${OPENSSL_OUTPUT_PATH_TARGET} \
    | tee -a /pjsip/build_pjsip.log
    build_library \
    | tee -a /pjsip/build_pjsip.log

else
    echo "Unsupported target ABI: $ANDROID_TARGET_ABI"
    exit 1
fi