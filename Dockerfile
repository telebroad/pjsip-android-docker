# syntax=docker/dockerfile:1
FROM ubuntu AS builder

LABEL authors="Isaac Weingarten, Yehuda Goldshtein"

ENV DOCKER_DEFAULT_PLATFORM=linux/amd64

RUN apt search openjdk

RUN apt-get update && \ 
    apt-get upgrade -y 
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get install -y git gcc build-essential unzip make openjdk-11-jdk swig libopus-dev tzdata
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


# downloading android NDK
ADD https://dl.google.com/android/repository/android-ndk-r26b-linux.zip .

RUN unzip android-ndk-r26b-linux.zip && \
    rm android-ndk-r26b-linux.zip

WORKDIR /pjsip/openssl_for_android

# downloading openssl-v3.2.0
ADD https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz .
RUN tar xzf openssl-3.2.0.tar.gz && \
    rm openssl-3.2.0.tar.gz

# starting the build for openssl 
# used https://github.com/217heidai/openssl_for_android/blob/master/openssl_build.sh
ENV OPENSSL_SOURCES_PATH=/pjsip/openssl_for_android/openssl-3.2.0
ENV ANDROID_NDK_ROOT=/pjsip/android-ndk-r26b
ENV ANDROID_TARGET_API=21
ENV ANDROID_TARGET_ABI_ARMV8=arm64-v8a
ENV ANDROID_TARGET_ABI_ARMV7=armeabi-v7a
ENV ANDROID_TARGET_ABI_AMD64=x86_64
ENV GCC_VERSION=11.4
ARG ANDROID_NDK_PLATFORM=
ENV APP_PLATFORM=${ANDROID_NDK_PLATFORM}

ENV WORK_PATH=/pjsip/openssl_for_android
# ENV OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.2.0
ENV OUTPUT_PATH=${WORK_PATH}/openssl_3.2.0

RUN chmod -R +x ${ANDROID_NDK_ROOT}
RUN chmod -R +x ${OPENSSL_SOURCES_PATH}

COPY ./build_openssl.sh .
RUN chmod +x ./build_openssl.sh
COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.

COPY build_pjsip.sh /pjsip/pjproject
RUN chmod +x /pjsip/pjproject/build_pjsip.sh



FROM builder AS build-ARMV8

ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV8}
WORKDIR /pjsip/openssl_for_android
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV8} ${GCC_VERSION}
WORKDIR /pjsip/pjproject
RUN ./build_pjsip.sh


FROM builder AS build-ARMV7
ENV TARGET_ABI=${ANDROID_TARGET_ABI_ARMV7}
WORKDIR /pjsip/openssl_for_android
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV7} ${GCC_VERSION}
WORKDIR /pjsip/pjproject
ENV CFLAGS=
RUN ./build_pjsip.sh


FROM builder AS build-AMD64
ENV TARGET_ABI=${ANDROID_TARGET_ABI_AMD64}
WORKDIR /pjsip/openssl_for_android
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_AMD64} ${GCC_VERSION}
WORKDIR /pjsip/pjproject
ENV CFLAGS=
RUN ./build_pjsip.sh


FROM builder

COPY --from=build-ARMV8 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
COPY --from=build-ARMV8 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
COPY --from=build-ARMV8 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV8}.log

COPY --from=build-ARMV7 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
COPY --from=build-ARMV7 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
COPY --from=build-ARMV7 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_ARMV7}.log

COPY --from=build-AMD64 /pjsip/pjproject/pjsip-apps/src/swig/java/android/pjsua2/src/main/jniLibs/ /pjsip/releases/jniLibs/
COPY --from=build-AMD64 /pjsip/openssl_for_android /pjsip/releases/openssl_for_android/
COPY --from=build-AMD64 /pjsip/build_pjsip.log /pjsip/releases/build_pjsip_${ANDROID_TARGET_ABI_AMD64}.log


WORKDIR /pjsip

COPY ./copy_results.sh .

ENTRYPOINT [ "/bin/sh", "-c", "./copy_results.sh"]