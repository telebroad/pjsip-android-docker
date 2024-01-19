FROM ubuntu 

LABEL authors="Isaac Weingarten, Yehuda Goldshtein"

ENV DOCKER_DEFAULT_PLATFORM=linux/amd64

RUN apt search openjdk

RUN apt-get update && \ 
    apt-get upgrade -y && \
    apt-get install git unzip make openjdk-11-jdk swig libopus-dev -y && \
    apt-get clean

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
ENV ANDROID_TARGET_ABI_V8=arm64-v8a
ENV ANDROID_TARGET_ABI_V7=armeabi-v7a
ENV GCC_VERSION=4.9

ENV WORK_PATH=/pjsip/openssl_for_android
ENV OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.2.0
ENV OUTPUT_PATH=${WORK_PATH}/openssl_3.2.0



ENV PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:${PATH}
COPY ./build_openssl.sh .
RUN ./build_openssl.sh ANDROID_TARGET_ABI_V8 & \
    ./build_openssl.sh ANDROID_TARGET_ABI_V7 & \
    wait

# Building pjsip with openssl

WORKDIR /pjsip/pjproject

COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.

COPY build_pjsip.sh .

RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_V8} ${OUTPUT_PATH}_${ANDROID_TARGET_ABI_V8} & \
    ./build_pjsip.sh ${ANDROID_TARGET_ABI_V7} ${OUTPUT_PATH}_${ANDROID_TARGET_ABI_V7} & \
    wait


WORKDIR /pjsip

COPY ./start.sh .


ENTRYPOINT ["./start.sh"]