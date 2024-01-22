#!/bin/sh

TARGET_ABI=$1
OUTPUT_PATH=$2
# https://docs.pjsip.org/en/latest/get-started/android/build_instructions.html#building-pjsip
echo "[$(date '+%Y-%m-%d %H:%M:%S')]: PJSIP-CONFIG :: ./configure-android --use-ndk-cflags --with-ssl=/pjsip/openssl_for_android/openssl-3.2.0" \
    | tee -a /pjsip/build_pjsip.log 

./configure-android --use-ndk-cflags --with-ssl=${OUTPUT_PATH} | tee -a /pjsip/build_pjsip.log 
echo "[$(date '+%Y-%m-%d %H:%M:%S')]: PJSIP-BUILD :: make dep && make clean && make" \
    | tee -a /pjsip/build_pjsip.log
make dep && make clean && make \
    | tee -a /pjsip/build_pjsip.log


cd /pjsip/pjproject/pjsip-apps/src/swig
echo "Processing element: $TARGET_ABI"
echo "[$(date '+%Y-%m-%d %H:%M:%S')]: APP-BUILD $TARGET_ABI :: make" >> /pjsip/build_pjsip.log 2>&1
make | tee -a /pjsip/build_pjsip.log


if [ "$TARGET_ABI" != "arm64-v8a" ]; then
    mv /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/arm64-v8a \
        /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/${TARGET_ABI}/
fi
