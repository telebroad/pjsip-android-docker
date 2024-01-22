#!/bin/sh

rm -r /pjsip/build/*
cp -r /pjsip/pjproject/pjsip /pjsip/build/
cp -r /pjsip/openssl_for_android /pjsip/build/
cp -r /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2 /pjsip/build/
cp /pjsip/build_pjsip.log /pjsip/build/


echo "to find files go to /pjsip/build/swig/java/android/pjsua2/src/main/jniLibs/"

echo "/pjsip/build should be bind to build"
echo "Done!"



tail -f /dev/null
