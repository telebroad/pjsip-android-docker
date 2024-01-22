FROM ubuntu 

LABEL authors="Isaac Weingarten, Yehuda Goldshtein"

ENV DOCKER_DEFAULT_PLATFORM=linux/amd64

RUN apt search openjdk

RUN apt-get update && \ 
    apt-get upgrade -y && \
    apt-get install git gcc build-essential unzip make openjdk-11-jdk swig libopus-dev -y && \
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
ENV ANDROID_TARGET_ABI_ARMV8=arm64-v8a
ENV ANDROID_TARGET_ABI_ARMV7=armeabi-v7a
ENV ANDROID_TARGET_ABI_AMD64=x86_64
ENV GCC_VERSION=11.4

ENV WORK_PATH=/pjsip/openssl_for_android
ENV OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.2.0
ENV OUTPUT_PATH=${WORK_PATH}/openssl_3.2.0



ENV PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:${PATH}
COPY ./build_openssl.sh .
RUN ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV8} ${GCC_VERSION} & \
    ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_ARMV7} ${GCC_VERSION} & \
    ./build_openssl.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI_AMD64} ${GCC_VERSION} & \
    wait

# Building pjsip with openssl

WORKDIR /pjsip/pjproject

COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.

COPY build_pjsip.sh .


# all other platforms need to be compiled before arm64-v8a because the compiler only outputs arm64-v8a folder
# https://docs.pjsip.org/en/latest/get-started/android/build_instructions.html#trying-our-sample-application-and-creating-your-own:~:text=If%20you%20are%20building%20for%20other%20target%20ABI%2C%20you%E2%80%99ll%20need%20to%20manually%20move
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_AMD64} ${OUTPUT_PATH}_${ANDROID_TARGET_ABI_AMD64}
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_ARMV7} ${OUTPUT_PATH}_${ANDROID_TARGET_ABI_ARMV7}
RUN ./build_pjsip.sh ${ANDROID_TARGET_ABI_ARMV8} ${OUTPUT_PATH}_${ANDROID_TARGET_ABI_ARMV8}



WORKDIR /pjsip

COPY ./start.sh .

ENV ANDROID_TARGET_ABIS="${ANDROID_TARGET_ABI_ARMV8},${ANDROID_TARGET_ABI_ARMV7}"
ENTRYPOINT ["./start.sh"]

# ENTRYPOINT [ "tail","-f","/dev/null" ]