FROM ubuntu 

LABEL authors="Isaac Weingarten, Yehuda Goldshtein"

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
ENV ANDROID_TARGET_ABI=arm64-v8a
ENV GCC_VERSION=4.9

ENV WORK_PATH=/pjsip/openssl_for_android
ENV OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.2.0
ENV OUTPUT_PATH=${WORK_PATH}/openssl_3.2.0_${ANDROID_TARGET_ABI}
ENV OPENSSL_TMP_FOLDER=/tmp/openssl_${ANDROID_TARGET_ABI}

RUN mkdir -p ${OPENSSL_TMP_FOLDER}
RUN cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}

ENV PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:${PATH}
WORKDIR ${OPENSSL_TMP_FOLDER}
RUN ./Configure android-arm64 -D__ANDROID_API__=${ANDROID_TARGET_API} -fPIC no-asm no-shared no-tests --prefix=${OUTPUT_PATH}
RUN mkdir -p ${OUTPUT_PATH}
RUN make && make install
RUN rm -rf ${OPENSSL_TMP_FOLDER}
RUN rm -rf ${OUTPUT_PATH}/bin
RUN rm -rf ${OUTPUT_PATH}/share
RUN rm -rf ${OUTPUT_PATH}/ssl
RUN rm -rf ${OUTPUT_PATH}/lib/engines*
RUN rm -rf ${OUTPUT_PATH}/lib/pkgconfig
RUN rm -rf ${OUTPUT_PATH}/lib/ossl-modules
RUN echo "Build completed! Check output libraries in ${OUTPUT_PATH}"

# Building pjsip with openssl
WORKDIR /pjsip/openssl_for_android/openssl-3.2.0

WORKDIR /pjsip/pjproject
ENV TARGET_ABI=${ANDROID_TARGET_ABI}
COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.

# https://docs.pjsip.org/en/latest/get-started/android/build_instructions.html#building-pjsip
RUN echo "[$(date '+%Y-%m-%d %H:%M:%S')]: PJSIP-CONFIG :: ./configure-android --use-ndk-cflags --with-ssl=/pjsip/openssl_for_android/openssl-3.2.0" >> /pjsip/build_pjsip.log 2>&1

RUN ./configure-android --use-ndk-cflags --with-ssl=${OUTPUT_PATH} >> /pjsip/build_pjsip.log 2>&1
RUN echo "[$(date '+%Y-%m-%d %H:%M:%S')]: PJSIP-BUILD :: make dep && make clean && make" >> /pjsip/build_pjsip.log 2>&1
RUN make dep && make clean && make >> /pjsip/build_pjsip.log 2>&1

# building the sample app to get the swig files

RUN cd /pjsip/pjproject/pjsip-apps/src/swig
RUN echo "[$(date '+%Y-%m-%d %H:%M:%S')]: APP-BUILD :: make"
RUN make >> /pjsip/build_pjsip.log 2>&1


WORKDIR /pjsip

COPY ./start.sh .


ENTRYPOINT ["./start.sh"]