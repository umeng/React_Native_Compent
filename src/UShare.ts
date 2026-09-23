/**
 * TurboModule Spec for UMShare
 *
 * 定义友盟分享模块的原生接口。方法名沿用旧版以降低迁移成本。
 * - share / auth / shareboard 由 Callback 改为 Promise
 * - platform 参数由数字 ID 改为字符串枚举
 * - share / shareboard 的内容参数合并为 shareParams 对象
 */
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // ---- 初始化（原生配置，可从 TS 传参） ----
  init(config: Object): void;

  // ---- 分享 ----

  /**
   * 分享到指定平台
   * @param platform 平台字符串枚举（如 'wechat_session'）
   * @param shareParams 分享内容 { text?, img?, webUrl?, title? }
   * @returns Promise<{ code: number, message: string }>
   */
  share(platform: string, shareParams: Object): Promise<Object>;

  /**
   * 弹出分享面板
   * @param shareParams 分享内容 { text?, img?, webUrl?, title? }
   * @param platforms 要展示的平台字符串枚举列表
   * @returns Promise<{ code: number, message: string }>
   */
  shareboard(shareParams: Object, platforms: string[]): Promise<Object>;

  // ---- 授权 ----

  /**
   * 第三方平台授权登录
   * @param platform 平台字符串枚举
   * @returns Promise<{ code: number, data: Object, message: string }>
   */
  auth(platform: string): Promise<Object>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('UMShareModule');
