#!/bin/bash
myPath="UMReactNative"
pro_name="ReactNative"
version="1.0.0"
platform="reactnative"
sharename="share_${platform}_$version.zip"
pushname="push_${platform}_$version.zip"
analyticsname="analytics_${platform}_$version.zip"
commonname="common_${platform}_$version.zip" 


sharedic=${pro_name}"/share/share_${platform}_$version/"
pushdic=${pro_name}"/push/push_${platform}_$version/"
analyticsdic=${pro_name}"/analytics/analytics_${platform}_$version/"
commonndic=${pro_name}"/common/common_${platform}_$version/" 


common_android="${commonndic}/common_android/"
common_ios="${commonndic}/common_ios/"
analytics_android="${analyticsdic}/analytics_android/"
analytics_ios="${analyticsdic}/analytics_ios/"
push_android="${pushdic}/push_android/"
push_ios="${pushdic}/push_ios/"
share_android="${sharedic}/share_android/"
share_ios="${sharedic}/share_ios/"
common_js="${commonndic}/js/"

rm -r ${pro_name}
rm -r ${pro_name}.zip


if [ ! -d "$pro_name" ]; then
	
 mkdir "$pro_name"

fi 
if [ ! -d "$common_android" ]; then
	
 mkdir -p "$common_android"
fi 
if [ ! -d "$common_ios" ]; then
	
 mkdir -p  "$common_ios"
fi 
if [ ! -d "$analytics_android" ]; then
	
 mkdir  -p "$analytics_android"
fi 
if [ ! -d "$analytics_ios" ]; then
	
 mkdir  -p "$analytics_ios"
fi 
if [ ! -d "$push_android" ]; then
	
 mkdir  -p "$push_android"
fi 
if [ ! -d "$push_ios" ]; then
	
 mkdir  -p "$push_ios"
fi 
if [ ! -d "$share_android" ]; then
	
 mkdir  -p "$share_android"
fi 
if [ ! -d "$share_ios" ]; then
	
 mkdir -p  "$share_ios"
fi 
if [ ! -d "$common_js" ]; then
	
 mkdir  -p "$common_js"
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


cd ${pro_name}
cd share
# zip -r -m $sharename . -i "/share_${platform}_$version/*"
cd ../../
cd ${pro_name}
cd push
# zip -r -m $pushname  . -i "/push_${platform}_$version/*"
cd ../../
cd ${pro_name}
cd analytics
# zip -r -m $analyticsname  . -i "/analytics_${platform}_$version/*"
cd ../../
cd ${pro_name}
cd common
# zip -r -m $commonname . -i  "/common_${platform}_$version/*"
cd ../../
zip -r -m ${pro_name}".zip" . -i "/${pro_name}/*"

#########################版本号修改##################################
# share修改
value=`cat alljson/UM_share.json | awk -F '"' '/platform_version/{print$4}'`
echo $value
sed -i '' "s/$value/$version/g" alljson/UM_share.json
# push修改
value=`cat alljson/UM_push.json | awk -F '"' '/platform_version/{print$4}'`
echo $value
sed -i '' "s/$value/$version/g" alljson/UM_push.json
# common
value=`cat alljson/UM_common.json | awk -F '"' '/platform_version/{print$4}'`
echo $value
sed -i '' "s/$value/$version/g" alljson/UM_common.json
# analytics
value=`cat alljson/UM_analytics.json | awk -F '"' '/platform_version/{print$4}'`
echo $value
sed -i '' "s/$value/$version/g" alljson/UM_analytics.json
#########################版本号修改##################################
./addlog.py