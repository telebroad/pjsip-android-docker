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