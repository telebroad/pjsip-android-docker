#!/bin/sh


FOLDER=$(date '+%Y_%m_%d_%H_%M_%S_%Z')

echo "FOLDER: $FOLDER"


# cp -r /pjsip/pjproject/pjsip /pjsip/build/$FOLDER
cp -r /pjsip/releases /pjsip/build/$FOLDER
wait


echo "to find files go to /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/"

echo "pjsip-android-docker:/pjsip/build/$FOLDER/pjsua2 is bind to /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2"
echo "Done!"


# to keep the bash from exting
# tail -f /dev/null
