/**
 * TurboModule Spec for UMPush
 *
 * 定义友盟推送模块的原生接口。方法名沿用旧版以降低迁移成本。
 * - Callback 改为 Promise（breaking change）
 * - register / getDeviceToken 保留，供注册与获取 token
 * - 新增事件系统、批量 Tag、推送控制、Badge
 */
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // ---- Tag 管理 ----
  addTag(tag: string): Promise<Object>;
  deleteTag(tag: string): Promise<Object>;
  listTag(): Promise<Object>;
  addTags(tags: Array<string>): Promise<Object>;
  removeTags(tags: Array<string>): Promise<Object>;

  // ---- Alias 管理 ----
  addAlias(alias: string, aliasType: string): Promise<Object>;
  addExclusiveAlias(alias: string, aliasType: string): Promise<Object>;
  deleteAlias(alias: string, aliasType: string): Promise<Object>;

  // ---- 注册与配置 ----

  /**
   * 注册推送服务
   *
   * Android：调用 PushAgent.register，返回 { code, deviceToken }
   * iOS：调用 UMessage 注册远程通知，返回 { code, granted }
   */
  register(): Promise<Object>;

  /**
   * 获取 DeviceToken
   *
   * Android：返回 PushAgent.getRegistrationId()
   * iOS：从 NSUserDefaults 读取 kUMessageUserDefaultKeyForDeviceToken
   */
  getDeviceToken(): Promise<string>;

  // ---- 推送控制 ----
  setPushEnable(enable: boolean): void;
  setBadge(num: number): void;
  openNotificationSettings(): void;
  isNotificationEnabled(): Promise<boolean>;

  // ---- 事件系统（Legacy Module 必需）----
  addListener(eventName: string): void;
  removeListeners(count: number): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('UMPushModule');
