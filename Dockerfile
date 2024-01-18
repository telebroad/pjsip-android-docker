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
RUN ./openssl_build.sh ${ANDROID_TARGET_API} ${ANDROID_TARGET_ABI} ${GCC_VERSION}
#Then copy the libraries into lib folder:
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