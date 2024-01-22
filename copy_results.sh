#!/bin/sh


FOLDER=$(date '+%Y_%m_%d_%H_%M_%S')

# cp -r /pjsip/pjproject/pjsip /pjsip/build/$FOLDER
cp -r /pjsip/openssl_for_android /pjsip/build/$FOLDER/openssl_for_android & \
cp -r /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2 /pjsip/build/$FOLDER/pjsua2 & \
cp /pjsip/build_pjsip.log /pjsip/build/$FOLDER & \
wait


echo "to find files go to /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/"

echo "pjsip-android-docker:/pjsip/build/$FOLDER/pjsua2 is bind to /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2"
echo "Done!"


# to keep the bash from exting
# tail -f /dev/null
