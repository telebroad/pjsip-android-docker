# syntax=docker/dockerfile:1
FROM ubuntu:latest AS builder

LABEL authors="Isaac Weingarten, Yehuda Goldshtein"

ENV DOCKER_DEFAULT_PLATFORM=linux/amd64

RUN apt search openjdk

RUN apt-get update && \
    apt-get upgrade -y


ARG DEBIAN_FRONTEND=noninteractive

#set video max resolution values
ARG MAX_RX_WIDTH=3840
ARG MAX_RX_HEIGHT=2160


ENV OPUS_VERSION=1.5.2
ENV OPUS_SOURCES_PATH=/pjsip/opus/opus-${OPUS_VERSION}
ENV OPENSSL_VERSION=openssl-3.4.0
ENV OPENSSL_SOURCES_PATH=/pjsip/openssl_for_android/${OPENSSL_VERSION}
ENV ANDROID_NDK_VERSION=r27c
ENV ANDROID_NDK_ROOT=/pjsip/android-ndk-${ANDROID_NDK_VERSION}
ENV ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
ENV ANDROID_TARGET_API=30
ENV ANDROID_TARGET_ABI_ARMV8=arm64-v8a
ENV VCPKG_TARGET_PLATFORM_ARMV8=arm64-android
ENV ANDROID_TARGET_ABI_ARMV7=armeabi-v7a
ENV VCPKG_TARGET_PLATFORM_ARMV7=arm-android
ENV ANDROID_TARGET_ABI_AMD64=x86_64
ENV VCPKG_TARGET_PLATFORM_AMD64=x64-android
ENV GCC_VERSION=11.4
ARG ANDROID_NDK_PLATFORM=android-30
ENV APP_PLATFORM=${ANDROID_NDK_PLATFORM}
ENV WORK_PATH=/pjsip/openssl_for_android

RUN apt-get install -y git gcc build-essential curl zip tar
RUN apt-get install -y unzip make cmake openjdk-11-jdk
RUN apt-get install -y swig libopus-dev tzdata automake autoconf libtool pkg-config


ARG TZ=New_York
ENV TZ=${TZ}

RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata
RUN apt-get clean

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

RUN java -version
RUN swig -version

WORKDIR /pjsip

RUN git clone https://github.com/pjsip/pjproject.git


# Modify MAX_RX_WIDTH and MAX_RX_HEIGHT in openh264.cpp and and_vid_mediacodec.cpp
RUN sed -i "s/#define MAX_RX_WIDTH\s\+[0-9]\+/#define MAX_RX_WIDTH            ${MAX_RX_WIDTH}/" /pjsip/pjproject/pjmedia/src/pjmedia-codec/openh264.cpp && \
    sed -i "s/#define MAX_RX_HEIGHT\s\+[0-9]\+/#define MAX_RX_HEIGHT           ${MAX_RX_HEIGHT}/" /pjsip/pjproject/pjmedia/src/pjmedia-codec/openh264.cpp && \
    sed -i "s/#define MAX_RX_WIDTH\s\+[0-9]\+/#define MAX_RX_WIDTH            ${MAX_RX_WIDTH}/" /pjsip/pjproject/pjmedia/src/pjmedia-codec/and_vid_mediacodec.cpp && \
    sed -i "s/#define MAX_RX_HEIGHT\s\+[0-9]\+/#define MAX_RX_HEIGHT           ${MAX_RX_HEIGHT}/" /pjsip/pjproject/pjmedia/src/pjmedia-codec/and_vid_mediacodec.cpp

# Log the results to verify the changes
RUN echo "Verifying changes in openh264.cpp:" && \
    grep '#define MAX_RX_WIDTH' /pjsip/pjproject/pjmedia/src/pjmedia-codec/openh264.cpp && \
    grep '#define MAX_RX_HEIGHT' /pjsip/pjproject/pjmedia/src/pjmedia-codec/openh264.cpp && \
    echo "Verifying changes in and_vid_mediacodec.cpp:" && \
    grep '#define MAX_RX_WIDTH' /pjsip/pjproject/pjmedia/src/pjmedia-codec/and_vid_mediacodec.cpp && \
    grep '#define MAX_RX_HEIGHT' /pjsip/pjproject/pjmedia/src/pjmedia-codec/and_vid_mediacodec.cpp

# downloading android NDK
#ADD https://dl.google.com/android/repository/android-ndk-r25b-linux.zip .
#RUN unzip android-ndk-r25b-linux.zip && \
#    rm android-ndk-r25b-linux.zip \

ADD https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux.zip .
RUN unzip android-ndk-${ANDROID_NDK_VERSION}-linux.zip && \
    rm android-ndk-${ANDROID_NDK_VERSION}-linux.zip
ENV PATH=$PATH:$ANDROID_NDK_ROOT
ENV PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"


## downloading openssl
#WORKDIR /pjsip/openssl_for_android
#ADD https://github.com/openssl/openssl/releases/download/${OPENSSL_VERSION}/${OPENSSL_VERSION}.tar.gz .
#RUN tar xzf ${OPENSSL_VERSION}.tar.gz && \
#    rm ${OPENSSL_VERSION}.tar.gz

## download opus
#WORKDIR /pjsip/opus
#
#ADD https://github.com/xiph/opus/releases/download/v${OPUS_VERSION}/opus-${OPUS_VERSION}.tar.gz .
#RUN tar xzf opus-${OPUS_VERSION}.tar.gz && \
#    rm opus-${OPUS_VERSION}.tar.gz


WORKDIR /
RUN git clone https://github.com/microsoft/vcpkg.git
WORKDIR /vcpkg
RUN ./bootstrap-vcpkg.sh
ENV VCPKG_ROOT=/vcpkg
ENV VCPKG_INSTALLED_DIR=${VCPKG_ROOT}/installed
ENV PATH="${VCPKG_ROOT}:${PATH}"
WORKDIR /pjsip/pjproject
COPY ./vcpkg.json .
RUN #vcpkg x-update-baseline --add-initial-baseline
RUN vcpkg version


# starting the build for openssl 
# used https://github.com/217heidai/openssl_for_android/blob/master/openssl_build.sh


RUN ndk-build --version

WORKDIR /pjsip/openssl_for_android

RUN chmod -R +x ${ANDROID_NDK_ROOT}
#RUN chmod -R +x ${OPENSSL_SOURCES_PATH}

COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.

#COPY ./build_openssl.sh /pjsip/openssl_for_android/.
#RUN chmod +x ./build_openssl.sh

#COPY ./build_opus.sh /pjsip/opus/.
#RUN chmod +x /pjsip/opus/build_opus.sh

COPY build_pjsip.sh /pjsip/pjproject
RUN chmod +x /pjsip/pjproject/build_pjsip.sh

#COPY ./Android.mk $OPUS_SOURCES_PATH/jni/.
#RUN chmod +x $OPUS_SOURCES_PATH/jni/Android.mk


#RUN vcpkg install opus openssl:x86-android



FROM builder AS build-armv8

ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV8}
WORKDIR /pjsip/pjproject
RUN #vcpkg install opus:arm64-android openssl:arm64-android
RUN vcpkg install --triplet arm64-android
ENV CFLAGS=
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_ARMV8} ${VCPKG_TARGET_PLATFORM_ARMV8}


#FROM builder AS build-armv7
#ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV7}
#RUN vcpkg install opus:arm-android openssl:arm-android
#WORKDIR /pjsip/pjproject
#ENV CFLAGS=
#RUN ./build_pjsip.sh arm-android


#FROM builder AS build-amd64
#ENV TARGET_ABI=${ANDROID_TARGET_ABI_AMD64}
#RUN vcpkg install opus:x64-android openssl:x64-android
#WORKDIR /pjsip/pjproject
#ENV CFLAGS=
#RUN ./build_pjsip.sh x64-android


FROM builder

# COPY --from=build-armv8 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
# coping the whole sample app
COPY --from=build-armv8 /pjsip/pjproject/pjsip-apps/src/swig/java /pjsip/releases/java/
#COPY --from=build-armv8 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
#COPY --from=build-armv8 /pjsip/opus /pjsip/releases/opus
COPY --from=build-armv8 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV8}.log
#COPY --from=build-armv8 /vcpkg/installed/ /pjsip/releases/vcpkg
#COPY --from=build-armv8 /pjsip/pjproject/vcpkg.json /pjsip/releases/.
COPY --from=build-armv8 /pjsip/pjproject/ /pjsip/releases/pjproject
## COPY --from=build-armv7 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
#COPY --from=build-armv7 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/java/android/pjsua2/src/main/jniLibs/
#COPY --from=build-armv7 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
#COPY --from=build-armv7 /pjsip/opus /pjsip/releases/opus
#COPY --from=build-armv7 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV7}.log
#
## COPY --from=build-amd64 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
#COPY --from=build-amd64 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/java/android/pjsua2/src/main/jniLibs/
#COPY --from=build-amd64 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
#COPY --from=build-amd64 /pjsip/opus /pjsip/releases/opus
#COPY --from=build-amd64 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_AMD64}.log


WORKDIR /pjsip

COPY ./copy_results.sh .

ENTRYPOINT [ "/bin/sh", "-c", "./copy_results.sh"]