# syntax=docker/dockerfile:1
FROM ubuntu:latest AS base
LABEL authors="Isaac Weingarten, Yehuda Goldshtein"

ENV ANDROID_TARGET_ABI_ARMV8=arm64-v8a
ENV VCPKG_TARGET_PLATFORM_ARMV8=arm64-android
ENV ANDROID_TARGET_ABI_ARMV7=armeabi-v7a
ENV VCPKG_TARGET_PLATFORM_ARMV7=arm-neon-android
ENV ANDROID_TARGET_ABI_AMD64=x86_64
ENV VCPKG_TARGET_PLATFORM_AMD64=x64-android

ENV DOCKER_DEFAULT_PLATFORM=linux/amd64
ARG CONF_DEBUG=false


RUN apt search openjdk

RUN apt update && \
    apt upgrade -y

ARG DEBIAN_FRONTEND=noninteractive
#set video max resolution values
ARG MAX_RX_WIDTH=3840
ARG MAX_RX_HEIGHT=2160

RUN apt -y --no-install-recommends install git g++ wget curl zip vim pkg-config tar cmake unzip ca-certificates
RUN apt install -y git gcc build-essential make openjdk-11-jdk dos2unix
RUN apt install -y swig tzdata automake autoconf libtool rsync pv


ARG TZ=New_York
ENV TZ=${TZ}

RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata
RUN apt clean

FROM base AS builder

ENV ANDROID_NDK_VERSION=r27c
ENV ANDROID_NDK_ROOT=/pjsip/android-ndk-${ANDROID_NDK_VERSION}
ENV ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
ENV ANDROID_TARGET_API=30

ENV GCC_VERSION=11.4
ARG ANDROID_NDK_PLATFORM=android-30
ENV APP_PLATFORM=${ANDROID_NDK_PLATFORM}
ENV WORK_PATH=/pjsip/openssl_for_android



ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

RUN java -version
RUN swig -version

WORKDIR /pjsip

RUN git clone https://github.com/pjsip/pjproject.git

WORKDIR /pjsip/pjproject
# to run other vesions of pjsip use the tag 2.15.1 or master
ARG PJSIP_VERSION=master
RUN git checkout ${PJSIP_VERSION}
WORKDIR /pjsip

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


ADD https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux.zip .
RUN unzip android-ndk-${ANDROID_NDK_VERSION}-linux.zip && \
    rm android-ndk-${ANDROID_NDK_VERSION}-linux.zip
RUN chmod -R +x ${ANDROID_NDK_ROOT}
ENV PATH=$PATH:$ANDROID_NDK_ROOT
ENV PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"

#installing vcpkg
WORKDIR /
RUN git clone https://github.com/microsoft/vcpkg.git
WORKDIR /vcpkg
RUN git fetch --tags
RUN git checkout $(git describe --tags $(git rev-list --tags --max-count=1))
RUN ./bootstrap-vcpkg.sh
ENV VCPKG_ROOT=/vcpkg
ENV VCPKG_INSTALLED_DIR=${VCPKG_ROOT}/installed
ENV PATH="${VCPKG_ROOT}:${PATH}"
WORKDIR /pjsip/pjproject
COPY ./vcpkg.json .
RUN dos2unix ./vcpkg.json

# run it only if the baseline is not created yet
#RUN #vcpkg x-update-baseline --add-initial-baseline

RUN vcpkg version

RUN ndk-build --version

COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.
RUN dos2unix /pjsip/pjproject/pjlib/include/pj/config_site.h
RUN chmod +x /pjsip/pjproject/pjlib/include/pj/config_site.h
COPY build_pjsip.sh /pjsip/pjproject
RUN dos2unix /pjsip/pjproject/build_pjsip.sh
RUN chmod +x /pjsip/pjproject/build_pjsip.sh


FROM builder AS build-armv8
ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV8}
WORKDIR /pjsip/pjproject
RUN vcpkg install --triplet ${VCPKG_TARGET_PLATFORM_ARMV8}
ENV CFLAGS=
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_ARMV8} ${VCPKG_TARGET_PLATFORM_ARMV8}


FROM builder AS build-armv7
ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV7}
WORKDIR /pjsip/pjproject
RUN vcpkg install --triplet ${VCPKG_TARGET_PLATFORM_ARMV7}
ENV CFLAGS=
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_ARMV7} ${VCPKG_TARGET_PLATFORM_ARMV7}


FROM builder AS build-amd64
ENV TARGET_ABI=${ANDROID_TARGET_ABI_AMD64}
WORKDIR /pjsip/pjproject
RUN vcpkg install --triplet ${VCPKG_TARGET_PLATFORM_AMD64}
ENV CFLAGS=
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_AMD64} ${VCPKG_TARGET_PLATFORM_AMD64}


FROM base AS final

# from=build-armv8 copy the whole sample app and from the other only the jniLibs
COPY --from=build-armv8 /pjsip/pjproject/pjsip-apps/src/swig/java /pjsip/releases/java/
COPY --from=build-armv8 /pjsip/pjproject/ /pjsip/releases/pjproject/${ANDROID_TARGET_ABI_ARMV8}
COPY --from=build-armv8 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV8}.log

COPY --from=build-armv7 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/java/android/pjsua2/src/main/jniLibs/
COPY --from=build-armv7 /pjsip/pjproject/ /pjsip/releases/pjproject/${ANDROID_TARGET_ABI_ARMV7}
COPY --from=build-armv7 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV7}.log

COPY --from=build-amd64 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/java/android/pjsua2/src/main/jniLibs/
COPY --from=build-amd64 /pjsip/pjproject/ /pjsip/releases/pjproject/${ANDROID_TARGET_ABI_AMD64}
COPY --from=build-amd64 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_AMD64}.log


WORKDIR /pjsip

COPY ./copy_results.sh /pjsip/.
RUN dos2unix /pjsip/copy_results.sh
RUN chmod +x ./copy_results.sh
ENV CONF_DEBUG=${CONF_DEBUG}
ENTRYPOINT [ "/bin/sh", "-c", "./copy_results.sh"]