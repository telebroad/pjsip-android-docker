#!/bin/sh -e

OPENSSL_OUTPUT_PATH=${OUTPUT_PATH}_${TARGET_ABI}

# https://docs.pjsip.org/en/latest/get-started/android/build_instructions.html#building-pjsip
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-CONFIG :: TARGET_ABI=${TARGET_ABI} ./configure-android --use-ndk-cflags --with-ssl=${OPENSSL_OUTPUT_PATH} --enable-video" 2>&1 \
    | tee -a /pjsip/build_pjsip.log 




./configure-android --use-ndk-cflags --with-ssl=${OPENSSL_OUTPUT_PATH} --enable-video 2>&1  | tee -a /pjsip/build_pjsip.log 
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-BUILD :: make dep && make clean && make" 2>&1 | tee -a /pjsip/build_pjsip.log

make dep && make clean && make 2>&1 | tee -a /pjsip/build_pjsip.log


cd ${PJ_PROJECT}/pjsip-apps/src/swig
# cd ${PJ_PROJECT}/pjsip-apps/src/pjsua/android/jni
echo "Processing element: $TARGET_ABI"
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: APP-BUILD $TARGET_ABI :: make"  2>&1 | tee -a /pjsip/build_pjsip.log
make -v 2>&1 | tee -a /pjsip/build_pjsip.log


# if [ "$TARGET_ABI" != "arm64-v8a" ]; then
#     mv /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/arm64-v8a \
#         /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/${TARGET_ABI}/
# fi
