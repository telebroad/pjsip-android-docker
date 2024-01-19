#!/bin/sh


ANDROID_TARGET_ABI=$1
T_OUTPUT_PATH=${OUTPUT_PATH}_${ANDROID_TARGET_ABI}
OPENSSL_TMP_FOLDER=/tmp/openssl_${ANDROID_TARGET_ABI}


mkdir -p ${OPENSSL_TMP_FOLDER}
cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}
cd ${OPENSSL_TMP_FOLDER}

echo "[$(date '+%Y-%m-%d %H:%M:%S')]: ./Configure android-arm64 -D__ANDROID_API__=${T_OUTPUT_PATH} -fPIC no-asm no-shared no-tests --prefix=${T_OUTPUT_PATH}" \
    | tee -a /pjsip/build_pjsip.log
./Configure android-arm64 -D__ANDROID_API__=${ANDROID_TARGET_API} -fPIC no-asm no-shared no-tests --prefix=${T_OUTPUT_PATH}
mkdir -p ${T_OUTPUT_PATH}
make && make install
rm -rf ${OPENSSL_TMP_FOLDER}
rm -rf ${T_OUTPUT_PATH}/bin
rm -rf ${T_OUTPUT_PATH}/share
rm -rf ${T_OUTPUT_PATH}/ssl
rm -rf ${T_OUTPUT_PATH}/lib/engines*
rm -rf ${T_OUTPUT_PATH}/lib/pkgconfig
rm -rf ${T_OUTPUT_PATH}/lib/ossl-modules
echo "[$(date '+%Y-%m-%d %H:%M:%S')]: Build-completed! :: Check output libraries in ${T_OUTPUT_PATH}" \
    | tee -a /pjsip/build_pjsip.log
