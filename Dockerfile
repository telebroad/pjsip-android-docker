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

RUN apt-get install -y git gcc build-essential
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
ADD https://dl.google.com/android/repository/android-ndk-r25b-linux.zip .

RUN unzip android-ndk-r25b-linux.zip && \
    rm android-ndk-r25b-linux.zip

WORKDIR /pjsip/openssl_for_android

# downloading openssl-v3.2.0
ADD https://github.com/openssl/openssl/releases/download/openssl-3.4.0/openssl-3.4.0.tar.gz .
RUN tar xzf openssl-3.4.0.tar.gz && \
    rm openssl-3.4.0.tar.gz

# download opus 
WORKDIR /pjsip/opus

# ADD https://github.com/xiph/opus/archive/refs/tags/v1.5.2.zip .
# RUN unzip v1.5.2.zip && \
#     rm v1.5.2.zip

ADD https://github.com/xiph/opus/releases/download/v1.5.2/opus-1.5.2.tar.gz .
RUN tar xzf opus-1.5.2.tar.gz && \
    rm opus-1.5.2.tar.gz


# starting the build for openssl 
# used https://github.com/217heidai/openssl_for_android/blob/master/openssl_build.sh
ENV OPUS_SOURCES_PATH=/pjsip/opus/opus-1.5.2
ENV OPENSSL_SOURCES_PATH=/pjsip/openssl_for_android/openssl-3.4.0
ENV ANDROID_NDK_ROOT=/pjsip/android-ndk-r25b
ENV ANDROID_TARGET_API=30
ENV ANDROID_TARGET_ABI_ARMV8=arm64-v8a
ENV ANDROID_TARGET_ABI_ARMV7=armeabi-v7a
ENV ANDROID_TARGET_ABI_AMD64=x86_64
ENV GCC_VERSION=11.4
ARG ANDROID_NDK_PLATFORM=
ENV APP_PLATFORM=${ANDROID_NDK_PLATFORM}

ENV WORK_PATH=/pjsip/openssl_for_android


WORKDIR /pjsip/openssl_for_android

RUN chmod -R +x ${ANDROID_NDK_ROOT}
RUN chmod -R +x ${OPENSSL_SOURCES_PATH}

COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.

COPY ./build_openssl.sh /pjsip/openssl_for_android/.
RUN chmod +x ./build_openssl.sh

COPY ./build_opus.sh /pjsip/opus/.
RUN chmod +x /pjsip/opus/build_opus.sh

COPY build_pjsip.sh /pjsip/pjproject
RUN chmod +x /pjsip/pjproject/build_pjsip.sh





FROM builder AS build-armv8

ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV8}
WORKDIR /pjsip/openssl_for_android
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV8} ${GCC_VERSION}
WORKDIR /pjsip/opus
RUN ./build_opus.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV8}
WORKDIR /pjsip/pjproject
RUN ./build_pjsip.sh


FROM builder AS build-armv7
ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV7}
WORKDIR /pjsip/openssl_for_android
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV7} ${GCC_VERSION}
WORKDIR /pjsip/opus
RUN ./build_opus.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV7}
WORKDIR /pjsip/pjproject
ENV CFLAGS=
RUN ./build_pjsip.sh


FROM builder AS build-amd64
ENV TARGET_ABI=${ANDROID_TARGET_ABI_AMD64}
WORKDIR /pjsip/openssl_for_android
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_AMD64} ${GCC_VERSION}
WORKDIR /pjsip/opus
RUN ./build_opus.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_AMD64}
WORKDIR /pjsip/pjproject
ENV CFLAGS=
RUN ./build_pjsip.sh


FROM builder

# COPY --from=build-armv8 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
# coping the whole sample app
COPY --from=build-armv8 /pjsip/pjproject/pjsip-apps/src/swig/java /pjsip/releases/java/
COPY --from=build-armv8 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
COPY --from=build-armv8 /pjsip/opus /pjsip/releases/opus
COPY --from=build-armv8 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV8}.log

# COPY --from=build-armv7 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
COPY --from=build-armv7 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/java/android/pjsua2/src/main/jniLibs/
COPY --from=build-armv7 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
COPY --from=build-armv7 /pjsip/opus /pjsip/releases/opus
COPY --from=build-armv7 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV7}.log

# COPY --from=build-amd64 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
COPY --from=build-amd64 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/java/android/pjsua2/src/main/jniLibs/
COPY --from=build-amd64 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
COPY --from=build-amd64 /pjsip/opus /pjsip/releases/opus
COPY --from=build-amd64 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_AMD64}.log


WORKDIR /pjsip

COPY ./copy_results.sh .

ENTRYPOINT [ "/bin/sh", "-c", "./copy_results.sh"]