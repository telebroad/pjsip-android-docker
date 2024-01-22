# PJSIP-ANDROID-DOCKER
## building pjsip for android arm64v8 

### pjsip is build with video on with SipOverTLS 

to build the docker run
```bash
$ docker compose build && docker compose up --force-recreate 
```

```powershell
ps> docker compose build && docker compose up --force-recreate 
```

the results files will be copied
to find files go to `pjsip-android-docker:/pjsip/build/swig/java/android/pjsua2/src/main/jniLibs/<Architecture>`
`pjsip-android-docker:/pjsip/build/$FOLDER/pjsua2` is bind to `/pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2`


