# PJSIP-ANDROID-DOCKER
## building pjsip for android arm64v8 armv7 amd64

### pjsip is build with video on with OpenSSL, Opus, and Bcg729

#### build on ubuntu 24.04
#### tested on 
- [**ubuntu** 24.04](https://hub.docker.com/_/ubuntu)
- [**PJSIP** 2.15.1](https://github.com/pjsip/pjproject/releases/tag/2.15.1)
- [**OpenSSL** 3.4.0](https://vcpkg.io/en/package/openssl)
- [**Opus** 1.5.2](https://vcpkg.io/en/package/opus)
- [**Bcg729** 1.1.1#3](https://vcpkg.io/en/package/bcg729)

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


