#!/bin/sh -ex
ANDROID_TARGET_ABI=$1
VCPKG_TARGET_PLATFORM=$2

VCPKG_OUTPUT_PATH=/pjsip/pjproject/vcpkg_installed/${VCPKG_TARGET_PLATFORM}/


# Check if the environment variable CONF_DEBUG is set to "true"
if [ "$CONF_DEBUG" = "true" ]; then
    # Uncomment line 39 (i.e. remove the leading "//") in the file
    sed -i '39s/^\/\///' /pjsip//pjproject/pjmedia/src/pjmedia/conference.c
fi


# https://docs.pjsip.org/en/latest/get-started/android/build_instructions.html#building-pjsip
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-CONFIG :: TARGET_ABI=${TARGET_ABI}
    ./configure-android \
    --use-ndk-cflags \
    --with-ssl=${VCPKG_OUTPUT_PATH} \
    --with-opus=${VCPKG_OUTPUT_PATH} \
    --with-bcg729=${VCPKG_OUTPUT_PATH} \
    --enable-video" \
    | tee -a /pjsip/build_pjsip.log

# building pjsip
CFLAGS="-g -O0" LDFLAGS="-g -O0" \
    ./configure-android \
    --use-ndk-cflags \
    --with-ssl=${VCPKG_OUTPUT_PATH} \
    --with-opus=${VCPKG_OUTPUT_PATH} \
    --with-bcg729=${VCPKG_OUTPUT_PATH} \
    --enable-video | \
tee -a /pjsip/build_pjsip.log

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-BUILD :: make dep && make clean && make" \
    | tee -a /pjsip/build_pjsip.log
make dep && make clean && make \
    | tee -a /pjsip/build_pjsip.log


cd /pjsip/pjproject/pjsip-apps/src/swig
echo "Processing element: $TARGET_ABI"
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: APP-BUILD $TARGET_ABI :: make" >> /pjsip/build_pjsip.log 2>&1
make | tee -a /pjsip/build_pjsip.log
