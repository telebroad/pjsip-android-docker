#!/bin/sh -e

echo "CONF_DEBUG=${CONF_DEBUG}"
echo "PJSIP_VERSION=${PJSIP_VERSION}"
FOLDER=$(date '+%Y_%m_%d_%H_%M_%S_%Z')

echo "FOLDER: ${FOLDER}-${PJSIP_VERSION}-${CONF_DEBUG}"

rsync -ahr --info=progress2 /pjsip/releases/ /pjsip/build/$FOLDER/ | pv -lep -s $(du -sb /pjsip/releases | awk '{print $1}')


prefix1="checking for openssl/ssl.h..."
grep "^${prefix1}" "/pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV8}.log"
grep "^${prefix1}" "/pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV7}.log"
grep "^${prefix1}" "/pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_AMD64}.log"

prefix2="checking for opus/opus.h..."
grep "^${prefix2}" "/pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV8}.log"
grep "^${prefix2}" "/pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV7}.log"
grep "^${prefix2}" "/pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_AMD64}.log"


echo "to find files go to /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/"

echo "pjsip-android-docker:/pjsip/build/$FOLDER/pjsua2 is bind to /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2"
# echo "Done!"


# to keep the bash from exting
echo "Press enter to exit"
read -r
