//
//  DplusMobClick.h
//  Analytics
//
//  Copyright (C) 2010-2016 Umeng.com . All rights reserved.

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface DplusMobClick : NSObject

/** Dplus增加事件
 @param eventName 事件名
 @param property 自定义属性
 */
+(void) track:(NSString *)eventName;
+(void) track:(NSString *)eventName property:(NSDictionary *) property;

/**
 * 设置属性 键值对 会覆盖同名的key
 * 将该函数指定的key-value写入dplus专用文件；APP启动时会自动读取该文件的所有key-value，并将key-value自动作为后续所有track事件的属性。
 */
+(void) registerSuperProperty:(NSDictionary *)property;

/**
 *
 * 从dplus专用文件中删除指定key-value
 @param key
 */
+(void) unregisterSuperProperty:(NSString *)propertyName;

/**
 *
 * 返回dplus专用文件中key对应的value；如果不存在，则返回空。
 @param key
 @return void
 */
+(NSString *)getSuperProperty:(NSString *)propertyName;

/**
 * 返回Dplus专用文件中的所有key-value；如果不存在，则返回空。
 */
+(NSDictionary *)getSuperProperties;

/**
 *清空Dplus专用文件中的所有key-value。
 */
+(void)clearSuperProperties;

/**
 * 设置预置事件属性 键值对 会覆盖同名的key
 */
+(void) registerPreProperties:(NSDictionary *)property;

/**
 *
 * 删除指定预置事件属性
 @param key
 */
+(void) unregisterPreProperty:(NSString *)propertyName;

/**
 * 获取预置事件所有属性；如果不存在，则返回空。
 */
+(NSDictionary *)getPreProperties;

/**
 *清空所有预置事件属性。
 */
+(void)clearPreProperties;


/**
 * 设置关注事件是否首次触发,只关注eventList前五个合法eventID.只要已经保存五个,此接口无效
 */
+(void)setFirstLaunchEvent:(NSArray *)eventList;
@end
