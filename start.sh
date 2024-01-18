#!/bin/sh



cp -r /pjsip/pjproject/pjsip /pjsip/build/
cp -r /pjsip/pjproject/pjsip-apps/src/swig /pjsip/build/
cp /pjsip/build_pjsip.log /pjsip/build/

echo "COPIED FILES"
echo "to find files go to /pjsip/build/swig/java/android/pjsua2/src/main/jniLibs/arm64-v8a"
echo "/pjsip/build should be bind to build"