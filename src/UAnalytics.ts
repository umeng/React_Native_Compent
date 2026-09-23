/**
 * TurboModule Spec for UMAnalytics
 *
 * 定义友盟统计模块的原生接口。方法名沿用旧版以降低迁移成本。
 * - getPreProperties 改为 Promise（breaking change）
 * - onEventWithLable 拼写修正为 onEventWithLabel
 * - iOS onPageBegin 统一为 onPageStart
 */
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // ---- 自定义事件 ----
  onEvent(eventId: string): void;
  onEventWithLabel(eventId: string, label: string): void;
  onEventWithMap(eventId: string, map: Object): void;
  onEventWithMapAndCount(eventId: string, map: Object, count: number): void;
  onEventObject(eventId: string, map: Object): void;

  // ---- 页面统计 ----
  onPageStart(pageName: string): void;
  onPageEnd(pageName: string): void;
  setPageCollectionModeAuto(): void;
  setPageCollectionModeManual(): void;

  // ---- 错误上报 ----
  reportError(error: string): void;

  // ---- 账号统计 ----
  profileSignInWithPUID(puid: string): void;
  profileSignInWithPUIDWithProvider(provider: string, puid: string): void;
  profileSignOff(): void;

  // ---- 超级属性（预置属性） ----
  registerPreProperties(map: Object): void;
  unregisterPreProperty(propertyName: string): void;
  getPreProperties(): Promise<string>;
  clearPreProperties(): void;

  // ---- 首次启动事件 ----
  setFirstLaunchEvent(eventList: string[]): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('UMAnalyticsModule');
