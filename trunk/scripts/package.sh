#!/bin/bash

echo "通用打包脚本，--help查看参数"

# Usage:
#       bash package.sh [--help]
#           option arm, whether build for arm, requires ubuntu12.

# user can config the following configs, then package.
INSTALL=/usr/local/srs
# whether build for arm, only for ubuntu12.
help=NO
X86_X64=NO
ARM=NO
PI=NO
MIPS=NO
#
EMBEDED=NO
JOBS=1
#
SRS_TAG=

##################################################################################
##################################################################################
##################################################################################
# parse options.
for option
do
    case "$option" in
        -*=*) 
            value=`echo "$option" | sed -e 's|[-_a-zA-Z0-9/]*=||'`
            option=`echo "$option" | awk -F '=' '{print $1}'`
        ;;
           *) value="" ;;
    esac
    
    case "$option" in
        -h)                             help=yes                  ;;
        --help)                         help=yes                  ;;
        
        --x86-x64)                      X86_X64=YES               ;;
        --x86-64)                       X86_X64=YES               ;;
        --mips)                         MIPS=YES                  ;;
        --arm)                          ARM=YES                   ;;
        --pi)                           PI=YES                    ;;
        --jobs)                         JOBS=$value               ;;
        --tag)                          SRS_TAG=$value               ;;

        *)
            echo "$0: error: invalid option \"$option\", @see $0 --help"
            exit 1
        ;;
    esac
done
if [ $help = yes ]; then
    cat << END

  --help                   Print this message

  --x86-x64                For x86-x64 platform, configure/make/package.
  --x86-64                 Alias for --x86-x64.
  --arm                    For arm cross-build platform, configure/make/package.
  --mips                   For mips cross-build platform, configure/make/package.
  --pi                     For pi platform, configure/make/package.
  --jobs                   Set the configure and make jobs.
  --tag                    Set the version in zip file.
END
    exit 0
fi

# embeded(arm/mips)
if [ $ARM = YES ]; then EMBEDED=YES; fi
if [ $MIPS = YES ]; then EMBEDED=YES; fi

# discover the current work dir, the log and access.
echo "argv[0]=$0"
if [[ ! -f $0 ]]; then 
    echo "directly execute the scripts on shell.";
    work_dir=`pwd`
else 
    echo "execute scripts in file: $0";
    work_dir=`dirname $0`; work_dir=`(cd ${work_dir} && pwd)`
fi
work_dir=`(cd ${work_dir}/.. && pwd)`
product_dir=$work_dir
build_objs=${work_dir}/objs
package_dir=${build_objs}/package

log="${build_objs}/logs/package.`date +%s`.log" && . ${product_dir}/scripts/_log.sh && check_log
ret=$?; if [[ $ret -ne 0 ]]; then exit $ret; fi

# check lsb_release
lsb_release -a >/dev/null 2>&1
ret=$?; if [[ $ret -ne 0 ]]; then 
	failed_msg "lsb_release not found. "
	failed_msg "to install on centos/debian(ubuntu/respberry-pi):"; 
	failed_msg "	sudo yum install -y lsb-release"; 
	failed_msg "	sudo aptitude install -y lsb-release";
	failed_msg "or centos7:"
	failed_msg "  sudo yum install -y redhat-lsb"
	exit $ret; 
fi

# check os version
os_name=`lsb_release --id|awk '{print $3}'` &&
os_release=`lsb_release --release|awk '{print $2}'` &&
os_major_version=`echo $os_release|awk -F '.' '{print $1}'` &&
os_machine=`uname -i`
ret=$?; if [[ $ret -ne 0 ]]; then failed_msg "lsb_release get os info failed."; exit $ret; fi
ok_msg "target os is ${os_name}-${os_major_version} ${os_release} ${os_machine}"

# for raspberry-pi
# use rasberry-pi instead all release
if [ $PI = YES ]; then
	uname -a|grep "raspberrypi"; if [[ 0 -eq $? ]]; then os_name="RaspberryPi"; fi
	if [[ "Raspbian" == $os_name ]]; then os_name="RaspberryPi"; fi
	# check the cpu machine
	if [[ "unknown" == $os_machine ]]; then os_machine=`uname -m`; fi
fi
ok_msg "real os is ${os_name}-${os_major_version} ${os_release} ${os_machine}"

# build srs
# @see https://github.com/ossrs/srs/wiki/v1_CN_Build
ok_msg "start build srs, ARM: $ARM, MIPS: $MIPS, PI: $PI, X86_64: $X86_X64, JOBS: $JOBS, TAG: $SRS_TAG"
if [ $ARM = YES ]; then
    (
        cd $work_dir && 
        ./configure --arm --jobs=$JOBS --prefix=$INSTALL --build-tag=${os_name}${os_major_version} && make
    ) >> $log 2>&1
elif [ $MIPS = YES ]; then
    (
        cd $work_dir && 
        ./configure --mips --jobs=$JOBS --prefix=$INSTALL --build-tag=${os_name}${os_major_version} && make
    ) >> $log 2>&1
elif [ $PI = YES ]; then
    (
        cd $work_dir && 
        ./configure --pi --jobs=$JOBS --prefix=$INSTALL --build-tag=${os_name}${os_major_version} && make
    ) >> $log 2>&1
elif [ $X86_X64 = YES ]; then
    (
        cd $work_dir && 
        ./configure --x86-x64 --jobs=$JOBS --prefix=$INSTALL --build-tag=${os_name}${os_major_version} && make
    ) >> $log 2>&1
else
    failed_msg "invalid option, must be --x86-x64/--arm/--mips/--pi, see --help"; exit 1;
fi
ret=$?; if [[ 0 -ne ${ret} ]]; then failed_msg "build srs failed"; exit $ret; fi
ok_msg "build srs success"

# install srs
ok_msg "start install srs"
(
    cd $work_dir && rm -rf $package_dir && make DESTDIR=$package_dir install
) >> $log 2>&1
ret=$?; if [[ 0 -ne ${ret} ]]; then failed_msg "install srs failed"; exit $ret; fi
ok_msg "install srs success"

# copy extra files to package.
ok_msg "start copy extra files to package"
(
    cp $work_dir/scripts/install.sh $package_dir/INSTALL &&
    sed -i "s|^INSTALL=.*|INSTALL=${INSTALL}|g" $package_dir/INSTALL &&
    mkdir -p $package_dir/scripts &&
    cp $work_dir/scripts/_log.sh $package_dir/scripts/_log.sh &&
    chmod +x $package_dir/INSTALL
) >> $log 2>&1
ret=$?; if [[ 0 -ne ${ret} ]]; then failed_msg "copy extra files failed"; exit $ret; fi
ok_msg "copy extra files success"

# detect for arm.
if [ $ARM = YES ]; then
    arm_cpu=`arm-linux-gnueabi-readelf --arch-specific ${build_objs}/srs|grep Tag_CPU_arch:|awk '{print $2}'`
    os_machine=arm${arm_cpu}cpu
fi
if [ $MIPS = YES ]; then
    os_machine=mips
fi
ok_msg "machine: $os_machine"

# generate zip dir and zip filename
srs_version=$SRS_TAG
if [[ $srs_version == '' ]]; then
    if [ $EMBEDED = YES ]; then
        srs_version_major=`cat $work_dir/src/core/srs_core.hpp| grep '#define VERSION_MAJOR'| awk '{print $3}'|xargs echo` &&
        srs_version_minor=`cat $work_dir/src/core/srs_core.hpp| grep '#define VERSION_MINOR'| awk '{print $3}'|xargs echo` &&
        srs_version_revision=`cat $work_dir/src/core/srs_core.hpp| grep '#define VERSION_REVISION'| awk '{print $3}'|xargs echo` &&
        srs_version=$srs_version_major.$srs_version_minor.$srs_version_revision
    else
        srs_version=`${build_objs}/srs -v 2>/dev/stdout 1>/dev/null`
    fi
    ret=$?; if [[ 0 -ne ${ret} ]]; then failed_msg "get srs version failed"; exit $ret; fi
fi
ok_msg "get srs version $srs_version"

zip_dir="SRS-${os_name}${os_major_version}-${os_machine}-${srs_version}"
ret=$?; if [[ 0 -ne ${ret} ]]; then failed_msg "generate zip filename failed"; exit $ret; fi
ok_msg "target zip filename $zip_dir"

# zip package.
ok_msg "start zip package"
(
    mv $package_dir ${build_objs}/${zip_dir} &&
    cd ${build_objs} && rm -rf ${zip_dir}.zip && zip -q -r ${zip_dir}.zip ${zip_dir} &&
    mv ${build_objs}/${zip_dir} $package_dir
) >> $log 2>&1
ret=$?; if [[ 0 -ne ${ret} ]]; then failed_msg "zip package failed"; exit $ret; fi
ok_msg "zip package success"

ok_msg "srs package success"
echo ""
echo "package: ${build_objs}/${zip_dir}.zip"
echo "install:"
echo "      unzip -q ${zip_dir}.zip &&"
echo "      cd ${zip_dir} &&"
echo "      sudo bash INSTALL"

exit 0
