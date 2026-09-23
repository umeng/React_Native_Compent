/**
 * UPush - 友盟推送公开 API
 *
 * 对 NativeUMPush TurboModule 的薄封装，增加参数校验。
 * 方法名与旧版一致以降低迁移成本。
 * Breaking change: 旧版 Callback 全部改为 Promise。
 * 新增：事件系统、批量 Tag、推送控制、Badge
 */
import { NativeEventEmitter, NativeModules } from 'react-native';
import NativeUMPush from '../UPush';

// ---- 事件系统 ----

const emitter = new NativeEventEmitter(NativeModules.UMPushModule);

export type PushEvent =
  | 'token'
  | 'message'
  | 'notificationReceive'
  | 'notificationOpen';

const EVENT_MAP: Record<PushEvent, string> = {
  token: 'UMPushOnToken',
  message: 'UMPushOnMessage',
  notificationReceive: 'UMPushOnNotificationReceive',
  notificationOpen: 'UMPushOnNotificationOpen',
};

/**
 * 添加推送事件监听
 * @returns subscription 对象，可调用 .remove() 取消监听
 */
export function addEventListener(
  event: PushEvent,
  callback: (payload: any) => void
) {
  return emitter.addListener(EVENT_MAP[event], callback);
}

/**
 * 移除指定事件的所有监听
 */
export function removeAllListeners(event: PushEvent) {
  emitter.removeAllListeners(EVENT_MAP[event]);
}

// ---- Tag 管理 ----

/**
 * 添加单个 Tag
 */
export function addTag(tag: string): Promise<Object> {
  if (!tag) {
    return Promise.reject(new Error('tag is required'));
  }
  return NativeUMPush.addTag(tag);
}

/**
 * 删除单个 Tag
 */
export function deleteTag(tag: string): Promise<Object> {
  if (!tag) {
    return Promise.reject(new Error('tag is required'));
  }
  return NativeUMPush.deleteTag(tag);
}

/**
 * 获取 Tag 列表
 */
export function listTag(): Promise<Object> {
  return NativeUMPush.listTag();
}

/**
 * 批量添加 Tags
 */
export function addTags(tags: string[]): Promise<Object> {
  if (!tags || tags.length === 0) {
    return Promise.reject(new Error('tags is required and cannot be empty'));
  }
  return NativeUMPush.addTags(tags);
}

/**
 * 批量删除 Tags
 */
export function removeTags(tags: string[]): Promise<Object> {
  if (!tags || tags.length === 0) {
    return Promise.reject(new Error('tags is required and cannot be empty'));
  }
  return NativeUMPush.removeTags(tags);
}

// ---- Alias 管理 ----

/**
 * 添加 Alias
 */
export function addAlias(alias: string, aliasType: string): Promise<Object> {
  if (!alias) {
    return Promise.reject(new Error('alias is required'));
  }
  if (!aliasType) {
    return Promise.reject(new Error('aliasType is required'));
  }
  return NativeUMPush.addAlias(alias, aliasType);
}

/**
 * 设置排他 Alias（会覆盖同类型旧 Alias）
 */
export function addExclusiveAlias(
  alias: string,
  aliasType: string
): Promise<Object> {
  if (!alias) {
    return Promise.reject(new Error('alias is required'));
  }
  if (!aliasType) {
    return Promise.reject(new Error('aliasType is required'));
  }
  return NativeUMPush.addExclusiveAlias(alias, aliasType);
}

/**
 * 删除 Alias
 */
export function deleteAlias(
  alias: string,
  aliasType: string
): Promise<Object> {
  if (!alias) {
    return Promise.reject(new Error('alias is required'));
  }
  if (!aliasType) {
    return Promise.reject(new Error('aliasType is required'));
  }
  return NativeUMPush.deleteAlias(alias, aliasType);
}

// ---- 注册与配置 ----

/**
 * 注册推送服务
 *
 * 注意：不会调用 UMConfigure.init，由 RNUMConfigure 统一初始化
 */
export function register(): Promise<Object> {
  return NativeUMPush.register();
}

/**
 * 获取 DeviceToken
 *
 * Android：返回 PushAgent.getRegistrationId()
 * iOS：从 NSUserDefaults 读取已缓存的 deviceToken (hex string)
 */
export function getDeviceToken(): Promise<string> {
  return NativeUMPush.getDeviceToken();
}

// ---- 推送控制 ----

/**
 * 设置推送开关
 * Android：调用 PushAgent.enable / disable
 * iOS：no-op（保留 API 一致性）
 */
export function setPushEnable(enable: boolean): void {
  NativeUMPush.setPushEnable(enable);
}

/**
 * 设置应用角标数
 * Android：PushAgent.setBadgeNum
 * iOS：UIApplication.applicationIconBadgeNumber
 */
export function setBadge(num: number): void {
  NativeUMPush.setBadge(num);
}

/**
 * 打开手机通知设置页面，引导用户开启通知权限
 * Android：PushAgent.openNotificationSettings()
 * iOS：跳转到 UIApplicationOpenSettingsURLString
 */
export function openNotificationSettings(): void {
  NativeUMPush.openNotificationSettings();
}

/**
 * 检查通知权限是否已开启
 * Android：PushAgent.isNotificationEnabled()
 * iOS：UNUserNotificationCenter getNotificationSettings
 */
export function isNotificationEnabled(): Promise<boolean> {
  return NativeUMPush.isNotificationEnabled();
}

// ---- 默认导出：兼容旧版 import 方式 ----

const UPush = {
  addTag,
  deleteTag,
  listTag,
  addTags,
  removeTags,
  addAlias,
  addExclusiveAlias,
  deleteAlias,
  register,
  getDeviceToken,
  setPushEnable,
  setBadge,
  openNotificationSettings,
  isNotificationEnabled,
  addEventListener,
  removeAllListeners,
};

export default UPush;
