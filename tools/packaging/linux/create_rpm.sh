# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

#!/usr/bin/env bash

set -e
echo "**********************************************************"
echo "Creating rpm file for Amazon Linux and RHEL, Arch: ${ARCH}"
echo "**********************************************************"

SPEC_FILE="tools/packaging/linux/build.spec"
BUILD_ROOT="`pwd`/build/rpmbuild"
WORK_DIR="`pwd`/build/rpmtar"
VERSION=`cat VERSION`
RPM_NAME=aws-observability-collector
AOC_ROOT=${WORK_DIR}/${RPM_NAME}-${VERSION}

echo "Creating rpmbuild workspace"
mkdir -p ${BUILD_ROOT}/{RPMS,SRPMS,BUILD,SOURCES,SPECS}

echo "Creating file structure"
mkdir -p ${AOC_ROOT}/opt/aws/aws-observability-collector/logs
mkdir -p ${AOC_ROOT}/opt/aws/aws-observability-collector/bin
mkdir -p ${AOC_ROOT}/opt/aws/aws-observability-collector/etc
mkdir -p ${AOC_ROOT}/opt/aws/aws-observability-collector/var
mkdir -p ${AOC_ROOT}/opt/aws/aws-observability-collector/doc
mkdir -p ${AOC_ROOT}/etc/init
mkdir -p ${AOC_ROOT}/etc/systemd/system
mkdir -p ${AOC_ROOT}/usr/bin
mkdir -p ${AOC_ROOT}/etc/amazon
mkdir -p ${AOC_ROOT}/var/log/amazon
mkdir -p ${AOC_ROOT}/var/run/amazon

echo "Copying application files"
# License, version, release note... 
cp LICENSE ${AOC_ROOT}/opt/aws/aws-observability-collector/
cp VERSION ${AOC_ROOT}/opt/aws/aws-observability-collector/bin/
cp docs/releases/${VERSION}.md ${AOC_ROOT}/opt/aws/aws-observability-collector/RELEASE_NOTE

# binary
cp build/linux/aoc_linux_${ARCH} ${AOC_ROOT}/opt/aws/aws-observability-collector/bin/aws-observability-collector
# ctl
cp tools/ctl/linux/aws-observability-collector-ctl ${AOC_ROOT}/opt/aws/aws-observability-collector/bin/
# default config
cp config.yaml ${AOC_ROOT}/opt/aws/aws-observability-collector/var/.config.yaml
# .env
cp .env ${AOC_ROOT}/opt/aws/aws-observability-collector/etc
# service config
cp tools/packaging/linux/aws-observability-collector.service ${AOC_ROOT}/etc/systemd/system/
cp tools/packaging/linux/aws-observability-collector.conf ${AOC_ROOT}/etc/init/

echo "assign permission to the files"
chmod ug+rx ${AOC_ROOT}/opt/aws/aws-observability-collector/bin/aws-observability-collector
chmod ug+rx ${AOC_ROOT}/opt/aws/aws-observability-collector/bin/aws-observability-collector-ctl
chmod ug+rx ${AOC_ROOT}/opt/aws/aws-observability-collector/var/.config.yaml
chmod ug+rx ${AOC_ROOT}/opt/aws/aws-observability-collector/etc/.env

echo "create symlinks"
ln -f -s /opt/aws/aws-observability-collector/bin/aws-observability-collector-ctl ${AOC_ROOT}/usr/bin/aws-observability-collector-ctl
ln -f -s /opt/aws/aws-observability-collector/etc ${AOC_ROOT}/etc/amazon/aws-observability-collector
ln -f -s /opt/aws/aws-observability-collector/logs ${AOC_ROOT}/var/log/amazon/aws-observability-collector
ln -f -s /opt/aws/aws-observability-collector/var ${AOC_ROOT}/var/run/amazon/aws-observability-collector

echo "build source tarball"
tar -czvf ${RPM_NAME}-${VERSION}.tar.gz -C ${WORK_DIR} .
mv ${RPM_NAME}-${VERSION}.tar.gz ${BUILD_ROOT}/SOURCES/
rm -rf ${WORK_DIR}

echo "Creating the rpm package"
rpmbuild --define "VERSION $VERSION" --define "RPM_NAME $RPM_NAME" --define "_topdir ${BUILD_ROOT}" -bb -v --clean ${SPEC_FILE} --target ${ARCH}-linux

echo "Copy rpm file to ${DEST}"
mkdir -p ${DEST}
cp ${BUILD_ROOT}/RPMS/${ARCH}/${RPM_NAME}-${VERSION}-1.${ARCH}.rpm ${DEST}/${RPM_NAME}.rpm