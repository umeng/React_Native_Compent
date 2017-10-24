#!/bin/bash
myPath="UMReactNative"
version="1.0"
common_android="${myPath}/common_android/"
common_ios="${myPath}/common_ios/"
analytics_android="${myPath}/analytics_android/"
analytics_ios="${myPath}/analytics_ios/"
push_android="${myPath}/push_android/"
push_ios="${myPath}/push_ios/"
share_android="${myPath}/share_android/"
share_ios="${myPath}/share_ios/"
common_js="${myPath}/js/"
rm -r ${myPath}
rm -r ${myPath}*.zip
if [ ! -d "$myPath" ]; then
	
 mkdir "$myPath"

fi 
if [ ! -d "$common_android" ]; then
	
 mkdir "$common_android"
fi 
if [ ! -d "$common_ios" ]; then
	
 mkdir "$common_ios"
fi 
if [ ! -d "$analytics_android" ]; then
	
 mkdir "$analytics_android"
fi 
if [ ! -d "$analytics_ios" ]; then
	
 mkdir "$analytics_ios"
fi 
if [ ! -d "$push_android" ]; then
	
 mkdir "$push_android"
fi 
if [ ! -d "$push_ios" ]; then
	
 mkdir "$push_ios"
fi 
if [ ! -d "$share_android" ]; then
	
 mkdir "$share_android"
fi 
if [ ! -d "$share_ios" ]; then
	
 mkdir "$share_ios"
fi 
if [ ! -d "$common_js" ]; then
	
 mkdir "$common_js"
fi 
## android common
cp ./android/app/src/main/java/com/umeng/soexample/invokenative/DplusReactPackage.java "$common_android"
cp ./android/app/src/main/java/com/umeng/soexample/invokenative/RNUMConfigure.java "$common_android"
## android 统计
cp ./android/app/src/main/java/com/umeng/soexample/invokenative/AnalyticsModule.java "$analytics_android"
## android 推送
cp ./android/app/src/main/java/com/umeng/soexample/invokenative/PushModule.java "$push_android"
cp -r ./android/push "$push_android"
## android 分享
cp ./android/app/src/main/java/com/umeng/soexample/invokenative/ShareModule.java "$share_android"

## ios common
cp ./ios/UMComponent/UMReactBridge/RNUMConfigure.h "$common_ios"
cp ./ios/UMComponent/UMReactBridge/RNUMConfigure.m "$common_ios"

## ios 统计
cp ./ios/UMComponent/UMReactBridge/UMAnalyticsModule.h "$analytics_ios"
cp ./ios/UMComponent/UMReactBridge/UMAnalyticsModule.m "$analytics_ios"
## ios 推送
cp ./ios/UMComponent/UMReactBridge/UMPushModule.h "$push_ios"
cp ./ios/UMComponent/UMReactBridge/UMPushModule.m "$push_ios"

## ios 分享
cp ./ios/UMComponent/UMReactBridge/UMShareModule.h "$share_ios"
cp ./ios/UMComponent/UMReactBridge/UMShareModule.m "$share_ios"
## js
cp ./native/* "$common_js"
zip -r ${myPath}${version}.zip ./${myPath}/*
./upload.sh