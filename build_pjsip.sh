#!/bin/sh -e

OPENSSL_OUTPUT_PATH=${WORK_PATH}/openssl_3.4.0_${TARGET_ABI}
OPUS_OUTPUT_PATH=/pjsip/opus/opus_${TARGET_ABI}  # Adjust if your install path differs

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-CONFIG :: TARGET_ABI=${TARGET_ABI} ./configure-android --use-ndk-cflags --with-ssl=${OPENSSL_OUTPUT_PATH} --with-opus=${OPUS_OUTPUT_PATH} --enable-video" \
    | tee -a /pjsip/build_pjsip.log

# Add include and lib paths for Opus so PJSIP can detect it
CFLAGS="-g -O0 -I${OPUS_OUTPUT_PATH}/include" LDFLAGS="-g -O0 -L${OPUS_OUTPUT_PATH}/lib" \
    ./configure-android \
    --use-ndk-cflags \
    --with-ssl=${OPENSSL_OUTPUT_PATH} \
    --with-opus=${OPUS_OUTPUT_PATH} \
    --enable-video \
    | tee -a /pjsip/build_pjsip.log

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: PJSIP-BUILD :: make dep && make clean && make" \
    | tee -a /pjsip/build_pjsip.log

make dep && make clean && make \
    | tee -a /pjsip/build_pjsip.log

cd /pjsip/pjproject/pjsip-apps/src/swig
echo "Processing element: $TARGET_ABI"
echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')]: APP-BUILD $TARGET_ABI :: make" >> /pjsip/build_pjsip.log 2>&1
make | tee -a /pjsip/build_pjsip.log
