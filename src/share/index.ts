/**
 * UShare - 友盟分享公开 API
 *
 * 对 NativeUMShare TurboModule 的薄封装，增加参数校验。
 * 方法名与旧版一致以降低迁移成本。
 */
import NativeUMShare from '../UShare';
import {
  Platform,
  VALID_PLATFORMS,
  DEPRECATED_PLATFORMS,
} from './platforms';

// ---- 重导出平台相关定义 ----

export {
  Platform,
  VALID_PLATFORMS,
  DEPRECATED_PLATFORMS,
  LEGACY_PLATFORM_MAP,
  resolveLegacyPlatform,
  GooglePlus,
  Renren,
  TencentWb,
  Douban,
  FacebookMessenger,
  Yixin,
  YixinCircle,
  Foursquare,
  More,
} from './platforms';
export type { SharePlatform } from './platforms';

// ---- 参数类型 ----

/** 分享内容参数 */
export interface ShareParams {
  /** 分享文本 */
  text?: string;
  /** 图片路径或 URL */
  img?: string;
  /** 网页链接 */
  webUrl?: string;
  /** 标题 */
  title?: string;
}

/** 分享结果 */
export interface ShareResult {
  code: number;
  message: string;
}

/** 授权结果 */
export interface AuthResult {
  code: number;
  data: Record<string, string>;
  message: string;
}

/**
 * 分享平台原生初始化配置（对应 Android UMShareConfig / iOS 配置）。
 * 通过 init(config) 从 TS 下发到原生。字段为空时对应平台跳过配置。
 */
export interface UMShareConfig {
  /** FileProvider authority（Android，需与 AndroidManifest 一致） */
  fileProvider?: string;
  /** 微信 AppId */
  weixinAppId?: string;
  /** 微信 AppSecret */
  weixinAppSecret?: string;
  /** QQ / QQ空间 AppId */
  qqAppId?: string;
  /** QQ / QQ空间 AppKey */
  qqAppKey?: string;
  /** 新浪微博 AppKey */
  sinaAppKey?: string;
  /** 新浪微博 AppSecret */
  sinaAppSecret?: string;
  /** 新浪微博 RedirectUrl */
  sinaRedirectUrl?: string;
  /** 钉钉 AppId */
  dingAppId?: string;
  /** iOS Universal Link（微博/微信 SDK 要求非空，否则崩溃；Android 忽略此字段） */
  universalLink?: string;
}

// ---- 内部工具 ----

/**
 * 校验平台字符串是否有效
 * - 已下线平台返回 E_PLATFORM_DEPRECATED 错误
 * - 未知平台返回 E_PLATFORM_UNSUPPORTED 错误
 */
function validatePlatform(platform: string): void {
  if (!platform) {
    throw new Error('E_PLATFORM_UNSUPPORTED: platform is required');
  }
  if (DEPRECATED_PLATFORMS.has(platform)) {
    throw new Error(
      `E_PLATFORM_DEPRECATED: platform "${platform}" is no longer available`
    );
  }
  if (!VALID_PLATFORMS.has(platform)) {
    throw new Error(
      `E_PLATFORM_UNSUPPORTED: platform "${platform}" is not supported`
    );
  }
}

// ---- 初始化 ----

/**
 * 分享平台初始化配置（可从 TS 传参）。凭证在原生层配置。
 *
 * iOS 上微博/微信 SDK 要求 universalLink 非空，需通过 config.universalLink 提供
 * （或已在 AppDelegate 配置 UMSocialGlobal.universalLinkDic），否则 setPlaform 会崩溃。
 */
export function init(config: UMShareConfig = {}): void {
  NativeUMShare.init(config as Object);
}

// ---- 分享 ----

/**
 * 分享到指定平台
 *
 * @param platform 平台字符串枚举（如 Platform.WechatSession）
 * @param shareParams 分享内容
 * @returns 分享结果 Promise
 */
export async function share(
  platform: string,
  shareParams: ShareParams = {}
): Promise<ShareResult> {
  validatePlatform(platform);
  const result = await NativeUMShare.share(platform, shareParams as Object);
  return result as unknown as ShareResult;
}

/**
 * 弹出分享面板，由用户选择平台后分享
 *
 * @param shareParams 分享内容
 * @param platforms 要展示的平台列表
 * @returns 分享结果 Promise
 */
export async function shareboard(
  shareParams: ShareParams = {},
  platforms: string[] = []
): Promise<ShareResult> {
  // 过滤无效平台
  const validPlatforms = platforms.filter((p) => VALID_PLATFORMS.has(p));
  const result = await NativeUMShare.shareboard(
    shareParams as Object,
    validPlatforms
  );
  return result as unknown as ShareResult;
}

// ---- 授权 ----

/**
 * 第三方平台授权登录
 *
 * @param platform 平台字符串枚举
 * @returns 授权结果 Promise（包含 uid, accessToken 等信息）
 */
export async function auth(platform: string): Promise<AuthResult> {
  validatePlatform(platform);
  const result = await NativeUMShare.auth(platform);
  return result as unknown as AuthResult;
}

// ---- 默认导出：兼容旧版 import 方式 ----

const UShare = {
  Platform,
  init,
  share,
  shareboard,
  auth,
};

export default UShare;
