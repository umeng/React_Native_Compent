#!/bin/bash
myPath="UMReactNative"
version="1.0.0"

sharename="upload/share/share_reactnative_$version.zip"
pushname="upload/push/push_reactnative_$version.zip"
analyticsname="upload/analytics/analytics_reactnative_$version.zip"
commonname="upload/common/common_reactnative_$version.zip"

common_android="UMCocos/common_java/java/com/umeng/common"
common_ios="UMCocos/common_cc/"
analytics_android="UMCocos/analytics_java/java/com/umeng/analytics"
analytics_ios="UMCocos/analytics_cc/"
push_android="UMCocos/push_java/java/com/umeng/push"
push_android_lib="UMCocos/push_java/"
push_ios="UMCocos/push_cc/"
share_android="UMCocos/share_java/java/com/umeng/share"
share_ios="UMCocos/share_cc/"

upload="upload"
upload_share="upload/share/"
upload_push="upload/push/"
upload_analytics="upload/analytics/"
upload_common="upload/common/"

if [ ! -d "$upload" ]; then
	
 mkdir "$upload"

fi 
if [ ! -d "$upload_share" ]; then
	
 mkdir -p "$upload_share"
fi 
if [ ! -d "$upload_push" ]; then
	
 mkdir -p "$upload_push"
fi 
if [ ! -d "$upload_analytics" ]; then
	
 mkdir -p "$upload_analytics"
fi 
if [ ! -d "$upload_common" ]; then
	
 mkdir -p "$upload_common"
fi 



cp ./${myPath}1.0.zip "$sharename"
cp ./${myPath}1.0.zip "$pushname"
cp ./${myPath}1.0.zip "$analyticsname"
cp ./${myPath}1.0.zip "$commonname"


zip -r upload.zip ./upload/*