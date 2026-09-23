/**
 * UAnalytics - 友盟统计公开 API
 *
 * 对 NativeUMAnalytics TurboModule 的薄封装，增加参数校验。
 * 方法名与旧版一致以降低迁移成本。
 */
import NativeUMAnalytics from '../UAnalytics';

// ---- 自定义事件 ----

/**
 * 计数事件
 */
export function onEvent(eventId: string): void {
  if (!eventId) {
    return;
  }
  NativeUMAnalytics.onEvent(eventId);
}

/**
 * 带标签的计数事件
 */
export function onEventWithLabel(eventId: string, label: string): void {
  if (!eventId) {
    return;
  }
  NativeUMAnalytics.onEventWithLabel(eventId, label ?? '');
}

/**
 * 带属性的计数事件（属性值为字符串）
 */
export function onEventWithMap(
  eventId: string,
  map: Record<string, string>
): void {
  if (!eventId) {
    return;
  }
  NativeUMAnalytics.onEventWithMap(eventId, map ?? {});
}

/**
 * 带属性和数值的事件
 */
export function onEventWithMapAndCount(
  eventId: string,
  map: Record<string, string>,
  count: number
): void {
  if (!eventId) {
    return;
  }
  NativeUMAnalytics.onEventWithMapAndCount(eventId, map ?? {}, count ?? 0);
}

/**
 * 带属性的计数事件（属性值为任意对象）
 */
export function onEventObject(
  eventId: string,
  map: Record<string, unknown>
): void {
  if (!eventId) {
    return;
  }
  NativeUMAnalytics.onEventObject(eventId, map ?? {});
}

// ---- 页面统计 ----

/**
 * 页面访问开始
 */
export function onPageStart(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUMAnalytics.onPageStart(pageName);
}

/**
 * 页面访问结束
 */
export function onPageEnd(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUMAnalytics.onPageEnd(pageName);
}

/**
 * 设置页面采集模式为自动（AUTO）
 */
export function setPageCollectionModeAuto(): void {
  NativeUMAnalytics.setPageCollectionModeAuto();
}

/**
 * 设置页面采集模式为手动（MANUAL）
 */
export function setPageCollectionModeManual(): void {
  NativeUMAnalytics.setPageCollectionModeManual();
}

// ---- 错误上报 ----

/**
 * 上报错误信息
 *
 * 注意：iOS 原生 SDK 不支持此 API，为空实现。
 */
export function reportError(error: string): void {
  if (!error) {
    return;
  }
  NativeUMAnalytics.reportError(error);
}

// ---- 账号统计 ----

/**
 * 账号登录（仅 PUID）
 */
export function profileSignInWithPUID(puid: string): void {
  if (!puid) {
    return;
  }
  NativeUMAnalytics.profileSignInWithPUID(puid);
}

/**
 * 账号登录（含 Provider）
 */
export function profileSignInWithPUIDWithProvider(
  provider: string,
  puid: string
): void {
  if (!puid) {
    return;
  }
  NativeUMAnalytics.profileSignInWithPUIDWithProvider(provider ?? '', puid);
}

/**
 * 账号登出
 */
export function profileSignOff(): void {
  NativeUMAnalytics.profileSignOff();
}

// ---- 超级属性（预置属性） ----

/**
 * 注册超级属性
 */
export function registerPreProperties(
  map: Record<string, unknown>
): void {
  NativeUMAnalytics.registerPreProperties(map ?? {});
}

/**
 * 移除单个超级属性
 */
export function unregisterPreProperty(propertyName: string): void {
  if (!propertyName) {
    return;
  }
  NativeUMAnalytics.unregisterPreProperty(propertyName);
}

/**
 * 获取超级属性（JSON 字符串）
 *
 * Breaking change: 旧版通过 Callback 返回，新版返回 Promise。
 */
export function getPreProperties(): Promise<string> {
  return NativeUMAnalytics.getPreProperties();
}

/**
 * 清除所有超级属性
 */
export function clearPreProperties(): void {
  NativeUMAnalytics.clearPreProperties();
}

// ---- 首次启动事件 ----

/**
 * 设置首次启动事件列表
 */
export function setFirstLaunchEvent(eventList: string[]): void {
  NativeUMAnalytics.setFirstLaunchEvent(eventList ?? []);
}

// ---- 默认导出：兼容旧版 import 方式 ----

const UAnalytics = {
  onEvent,
  onEventWithLabel,
  onEventWithMap,
  onEventWithMapAndCount,
  onEventObject,
  onPageStart,
  onPageEnd,
  setPageCollectionModeAuto,
  setPageCollectionModeManual,
  reportError,
  profileSignInWithPUID,
  profileSignInWithPUIDWithProvider,
  profileSignOff,
  registerPreProperties,
  unregisterPreProperty,
  getPreProperties,
  clearPreProperties,
  setFirstLaunchEvent,
};

export default UAnalytics;
