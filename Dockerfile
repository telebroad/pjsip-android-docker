FROM ubuntu 

RUN apt search openjdk

RUN apt-get update && \ 
    apt-get upgrade -y && \
    apt-get install git unzip make openjdk-11-jdk libopus-dev wget -y && \
    apt-get clean

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64


RUN java -version

WORKDIR /pjsip

RUN git clone https://github.com/pjsip/pjproject.git


# downloading android NDK
RUN wget https://dl.google.com/android/repository/android-ndk-r26b-linux.zip && \
    unzip android-ndk-r26b-linux.zip
RUN rm android-ndk-r26b-linux.zip




WORKDIR /pjsip/openssl_for_android

COPY openssl_build.sh .


# downloading openssl-v3.2.0
ADD https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz .
RUN tar xzf openssl-3.2.0.tar.gz

RUN chmod a+x openssl_build.sh
# starting the build for openssl 

ENV OPENSSL_SOURCES_PATH=/pjsip/openssl_for_android/openssl-3.2.0
ENV ANDROID_NDK_ROOT=/pjsip/android-ndk-r26b
ENV ANDROID_TARGET_API=21
ENV ANDROID_TARGET_ABI=arm64-v8a
ENV GCC_VERSION=4.9

# ENV WORK_PATH=/pjsip/openssl_for_android
# ENV OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.2.0
# ENV OUTPUT_PATH=${WORK_PATH}/openssl_3.2.0_${ANDROID_TARGET_ABI}
# ENV OPENSSL_TMP_FOLDER=/tmp/openssl_${ANDROID_TARGET_ABI}

# RUN mkdir -p ${OPENSSL_TMP_FOLDER}
# RUN cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}

# RUN PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:${ANDROID_NDK_ROOT}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin:$PATH
# WORKDIR ${OPENSSL_TMP_FOLDER}
RUN ./openssl_build.sh 
# RUN ./Configure android-arm64 -D__ANDROID_API__=${ANDROID_TARGET_API} -static no-asm no-shared no-tests --prefix=${OUTPUT_PATH}
# WORKDIR ${OUTPUT_PATH}
# RUN mkdir -p ${OUTPUT_PATH}
# RUN make && make install
# RUN rm -rf ${OPENSSL_TMP_FOLDER}
# RUN rm -rf ${OUTPUT_PATH}/bin
# RUN rm -rf ${OUTPUT_PATH}/share
# RUN rm -rf ${OUTPUT_PATH}/ssl
# RUN rm -rf ${OUTPUT_PATH}/lib/engines*
# RUN rm -rf ${OUTPUT_PATH}/lib/pkgconfig
# RUN rm -rf ${OUTPUT_PATH}/lib/ossl-modules
# RUN echo "Build completed! Check output libraries in ${OUTPUT_PATH}"



# RUN ./openssl_build.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI} ${GCC_VERSION}
WORKDIR /pjsip/openssl_for_android/openssl-3.2.0

WORKDIR /pjsip/pjproject
ENV TARGET_ABI=${ANDROID_TARGET_ABI}
COPY config_site.h /pjsip/pjproject/pjlib/include/pj/.
# RUN make depend
# RUN make all
# https://docs.pjsip.org/en/latest/get-started/android/build_instructions.html#building-pjsip
RUN ./configure-android --use-ndk-cflags --with-ssl=/pjsip/openssl_for_android/openssl-3.2.0
RUN make dep && make clean && make

WORKDIR /pjsip

COPY ./start.sh .

WORKDIR /pjsip/pjproject/pjsip-apps/src/swig
# RUN make

ENTRYPOINT ["./start.sh"]