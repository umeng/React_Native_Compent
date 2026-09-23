/**
 * TurboModule Spec for UAPM
 *
 * 定义友盟 APM 性能监控模块的原生接口。
 * 全新模块，方法名直接对齐友盟官方 APM SDK 语义命名。
 */
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // ---- 初始化（原生配置，可从 TS 传参） ----
  init(config: Object): void;

  // ---- 异常上报 ----
  reportException(
    name: string,
    reason: string,
    stackTrace: string[],
    extra: Object
  ): void;

  // ---- 自定义日志 ----
  log(tag: string, message: string, level: string): void;

  // ---- 自定义维度 ----
  setCustomStringParam(key: string, value: string): void;

  // ---- 启动耗时 ----
  beginLaunch(methodName: string): void;
  endLaunch(methodName: string): void;

  // ---- 页面耗时 ----
  beginPageTrace(methodName: string): void;
  endPageTrace(methodName: string): void;

  // ---- 页面性能追踪（FP/FCP/TTI）----
  beginPagePerf(pageName: string): void;
  markPageFP(pageName: string): void;
  markPageFCP(pageName: string): void;
  markPageTTI(pageName: string): void;
  endPagePerf(pageName: string): void;

  // ---- 页面帧率追踪 ----
  beginPageFps(pageName: string): void;
  endPageFps(pageName: string): void;

  // ---- HTTP API 监控 ----
  trackApiBegin(requestId: string, uri: string, method: string): void;
  trackApiEnd(
    requestId: string,
    statusCode: number,
    spend: number,
    reqSize: number,
    resSize: number,
    type: number,
    message: string
  ): void;

  // ---- 版本设置 ----
  setAppVersion(appVersion: string, buildVersion: string): void;

  // ---- SDK 信息查询 ----
  getSdkVersion(): Promise<string>;
  getDeviceMaxFps(): Promise<number>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('UMAPMModule');
