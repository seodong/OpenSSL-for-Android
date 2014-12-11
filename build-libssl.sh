#!/bin/sh
set -e

#################################################################################
VERSION="1.0.1j" 
ANDROID_NDK="/opt/sdk/ndk";
export PATH="${PATH:+$PATH:}$ANDROID_NDK/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-x86_64/bin"
ARCHS="armeabi armeabi-v7a"

CONFIG_ARGS="no-shared zlib-dynamic enable-tlsext"
#################################################################################


if [ ! -e openssl-${VERSION}.tar.gz ]; then
	echo "Downloading openssl-${VERSION}.tar.gz"
	curl -O http://www.openssl.org/source/openssl-${VERSION}.tar.gz
else
	echo "Using openssl-${VERSION}.tar.gz"
fi


if [ ! -d ${ANDROID_NDK} ]; then
	echo "Can not find root ANDROID_NDK"
	exit 1 ;
fi

COMPILER=""
CURRENTPATH=`pwd`

mkdir -p "${CURRENTPATH}/src"
#mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/libs"

tar zxf openssl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/openssl-${VERSION}"


for arch in ${ARCHS}
do
	if [ "${arch}" = "armeabi" ] ; then
		COMPILER="android"
		AR="arm-linux-androideabi-ar"
		RANLIB="arm-linux-androideabi-ranlib"
		export MACHINE=armv7l
		export RELEASE=2.6.39
		export SYSTEM=android
		export ARCH=arm
		export CROSS_COMPILE="arm-linux-androideabi-"
		export ANDROID_DEV="$ANDROID_NDK/platforms/android-14/arch-arm/usr"
		export HOSTCC=gcc
	fi
	if [ "${arch}" = "android-armv7" ] ; then
		export MACHINE=armv7l
		export RELEASE=2.6.39
		export SYSTEM=android
		export ARCH=arm
		export CROSS_COMPILE="arm-linux-androideabi-"
		export ANDROID_DEV="$ANDROID_NDK/platforms/android-14/arch-arm/usr"
		export HOSTCC=gcc
		COMPILER="android-armv7"
		#AR="arm-linux-androideabi-ar"
		#RANLIB="arm-linux-androideabi-ranlib"
	fi
	if [ "${arch}" = "amd64" ] ; then
		export MACHINE=armv7l
		export RELEASE=2.6.39
		export SYSTEM=android
		export ARCH=x86_64
		export CROSS_COMPILE="x86_64-linux-android-"
		COMPILER="linux-x86_64"
		export HOSTCC=gcc
		#AR="ar"
		#RANLIB="ranlib"
	fi

dest="${CURRENTPATH}/libs/${arch}"
cd "${CURRENTPATH}/src/openssl-${VERSION}"

	[ -f Makefile  ] && make clean
	./Configure ${COMPILER} --prefix=$dest --openssldir=/etc $CONFIG_ARGS
	make depend
	make
	[ -d  $dest ] || mkdir -p $dest
	#[ -f $dest/libopenssl.a ] && rm -f $dest/libopenssl.a
	cp -af libssl.a libcrypto.a  $dest/
	make clean
done


cd ${CURRENTPATH}
LIBOPENSSL_H=`find ${CURRENTPATH}/src/openssl-${VERSION}/include -name "*.h"`

[ -d include/openssl ] || mkdir -p include/openssl

for i in $LIBOPENSSL_H ; do
	HEADER=`realpath $i`;
	cp -f $HEADER include/openssl/ 
done
