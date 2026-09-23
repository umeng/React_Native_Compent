/**
 * UAPM - 友盟性能监控公开 API
 *
 * 对 NativeUAPM TurboModule 的薄封装，增加参数校验。
 * 全新模块，方法名直接对齐友盟官方 APM SDK 语义命名。
 */
import NativeUAPM from '../UAPM';

// ---- 类型定义 ----

export enum LogLevel {
  Verbose = 'verbose',
  Debug = 'debug',
  Info = 'info',
  Warn = 'warn',
  Error = 'error',
}

/**
 * APM 原生初始化配置（对应 Android UMAPMConfig / iOS RNUMAPMConfig）。
 * 通过 init(config) 从 TS 下发到原生。
 */
export interface UMAPMConfig {
  /**
   * 崩溃与卡顿监控（默认 true）。
   * iOS 对应 SDK 单一开关 crashAndBlockMonitorEnable；
   * Android 同时写入 KEY_ENABLE_CRASH_JAVA / CRASH_NATIVE / ANR / PA 四个 key。
   */
  crashAndBlockMonitorEnable?: boolean;
  /** 启动监控 */
  launchMonitorEnable?: boolean;
  /** 内存监控 */
  memMonitorEnable?: boolean;
  /** 网络监控 */
  networkEnable?: boolean;
  /** 页面监控 */
  pageMonitorEnable?: boolean;
  /** 日志回捞 */
  logCollectEnable?: boolean;
  /** H5 / JSBridge 监控 */
  javaScriptBridgeEnable?: boolean;
  /** 自定义 App 版本号 */
  appVersion?: string;
  /** 构建版本号 */
  buildVersion?: string;
}

// ---- 初始化 ----

/**
 * APM 初始化配置（可从 TS 传参）。
 *
 * 注意：Android 上 UMCrash.initConfig 只有在 UMConfigure.init 之前调用才生效；
 * 若宿主已在原生 init 流程配置过 APM，此处再调用通常不再生效。
 * 用于纯 JS 驱动初始化的场景，需在触发原生 init 之前调用。
 */
export function init(config: UMAPMConfig = {}): void {
  NativeUAPM.init(config as Object);
}

// ---- 异常上报 ----

/**
 * 上报自定义异常
 *
 * @param name 异常类型名称
 * @param reason 异常原因描述
 * @param stackTrace 调用栈信息（字符串数组）
 * @param extra 附加信息（键值对），可选；会随异常一起上报
 */
export function reportException(
  name: string,
  reason: string,
  stackTrace: string[],
  extra?: Record<string, any>
): void {
  if (!name) {
    return;
  }
  NativeUAPM.reportException(name, reason ?? '', stackTrace ?? [], extra ?? {});
}

// ---- 自定义日志 ----

/**
 * 自定义日志（用于崩溃附加信息、日志回捞等）
 *
 * @param tag 日志标签
 * @param message 日志内容
 * @param level 日志级别
 */
export function log(
  tag: string,
  message: string,
  level: LogLevel = LogLevel.Info
): void {
  if (!message) {
    return;
  }
  NativeUAPM.log(tag ?? '', message, level);
}

// ---- 自定义维度 ----

/**
 * 设置自定义字符串参数
 */
export function setCustomStringParam(key: string, value: string): void {
  if (!key) {
    return;
  }
  NativeUAPM.setCustomStringParam(key, value ?? '');
}

// ---- 启动耗时 ----

/**
 * 标记启动开始
 */
export function beginLaunch(methodName: string): void {
  if (!methodName) {
    return;
  }
  NativeUAPM.beginLaunch(methodName);
}

/**
 * 标记启动结束
 */
export function endLaunch(methodName: string): void {
  if (!methodName) {
    return;
  }
  NativeUAPM.endLaunch(methodName);
}

// ---- 页面耗时 ----

/**
 * 标记页面加载开始
 */
export function beginPageTrace(methodName: string): void {
  if (!methodName) {
    return;
  }
  NativeUAPM.beginPageTrace(methodName);
}

/**
 * 标记页面加载结束
 */
export function endPageTrace(methodName: string): void {
  if (!methodName) {
    return;
  }
  NativeUAPM.endPageTrace(methodName);
}

// ---- 页面性能追踪（FP/FCP/TTI）----

/**
 * 开始页面性能追踪，记录页面起始时间戳
 */
export function beginPagePerf(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.beginPagePerf(pageName);
}

/**
 * 标记首像素渲染完成（First Paint）
 */
export function markPageFP(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.markPageFP(pageName);
}

/**
 * 标记首次内容渲染完成（First Contentful Paint）
 */
export function markPageFCP(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.markPageFCP(pageName);
}

/**
 * 标记页面可交互（Time To Interactive）
 */
export function markPageTTI(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.markPageTTI(pageName);
}

/**
 * 结束页面性能追踪，汇总 FP/FCP/TTI 耗时并上报
 */
export function endPagePerf(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.endPagePerf(pageName);
}

// ---- 页面帧率追踪 ----

/**
 * 开始页面帧率采集
 */
export function beginPageFps(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.beginPageFps(pageName);
}

/**
 * 结束页面帧率采集，计算平均 FPS 并上报
 */
export function endPageFps(pageName: string): void {
  if (!pageName) {
    return;
  }
  NativeUAPM.endPageFps(pageName);
}

// ---- HTTP API 监控 ----

/**
 * 标记一次 HTTP 请求开始
 *
 * @param requestId 请求唯一标识（用于配对 begin/end）
 * @param uri 请求 URI
 * @param method 请求方法（GET/POST 等）
 */
export function trackApiBegin(
  requestId: string,
  uri: string,
  method: string
): void {
  if (!requestId) {
    return;
  }
  NativeUAPM.trackApiBegin(requestId, uri ?? '', method ?? '');
}

/**
 * 标记一次 HTTP 请求结束并上报
 *
 * @param requestId 请求唯一标识
 * @param statusCode HTTP 状态码
 * @param spend 耗时（毫秒）
 * @param reqSize 请求体大小（字节）
 * @param resSize 响应体大小（字节）
 * @param type 请求类型（业务自定义）
 * @param message 附加描述/错误信息
 */
export function trackApiEnd(
  requestId: string,
  statusCode: number,
  spend: number,
  reqSize: number,
  resSize: number,
  type: number,
  message: string
): void {
  if (!requestId) {
    return;
  }
  NativeUAPM.trackApiEnd(
    requestId,
    statusCode ?? 0,
    spend ?? 0,
    reqSize ?? 0,
    resSize ?? 0,
    type ?? 0,
    message ?? ''
  );
}

// ---- 版本设置 ----

/**
 * 设置自定义 App 版本
 *
 * @param appVersion 应用版本号
 * @param buildVersion 构建版本号
 */
export function setAppVersion(
  appVersion: string,
  buildVersion: string
): void {
  if (!appVersion) {
    return;
  }
  NativeUAPM.setAppVersion(appVersion, buildVersion ?? '');
}

// ---- SDK 信息查询 ----

/**
 * 获取原生 APM SDK 版本号
 */
export function getSdkVersion(): Promise<string> {
  return NativeUAPM.getSdkVersion();
}

/**
 * 获取设备最大刷新率（FPS）
 */
export function getDeviceMaxFps(): Promise<number> {
  return NativeUAPM.getDeviceMaxFps();
}

// ---- 默认导出：兼容命名空间 import 方式 ----

const UAPM = {
  init,
  reportException,
  log,
  setCustomStringParam,
  beginLaunch,
  endLaunch,
  beginPageTrace,
  endPageTrace,
  beginPagePerf,
  markPageFP,
  markPageFCP,
  markPageTTI,
  endPagePerf,
  beginPageFps,
  endPageFps,
  trackApiBegin,
  trackApiEnd,
  setAppVersion,
  getSdkVersion,
  getDeviceMaxFps,
};

export default UAPM;
