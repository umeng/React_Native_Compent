/**
 * UShare - 分享平台枚举与旧版兼容映射
 *
 * 以 U-Share SDK 当前版本为准，覆盖 Android/iOS 全部有效平台。
 * JS 层统一使用字符串枚举，原生适配层分别映射到
 * Android SHARE_MEDIA 和 iOS UMSocialPlatformType。
 */

// ======================== 活跃平台枚举 ========================

/**
 * 分享平台字符串枚举（25 个有效平台）
 *
 * 值为稳定的 snake_case 字符串，跨版本不变；
 * 原生层自行映射到各端 SDK 枚举。
 * 仅收录 Android SHARE_MEDIA 与 iOS UMSocialPlatformType
 * 双端均有映射的平台。
 */
export enum Platform {
  /** 微信好友 */
  WechatSession = 'wechat_session',
  /** 微信朋友圈 */
  WechatTimeline = 'wechat_timeline',
  /** 微信收藏 */
  WechatFavorite = 'wechat_favorite',
  /** QQ */
  QQ = 'qq',
  /** QQ空间 */
  QZone = 'qzone',
  /** 新浪微博 */
  Sina = 'sina',
  /** 支付宝 */
  Alipay = 'alipay',
  /** 钉钉 */
  DingTalk = 'dingtalk',
  /** 短信 */
  SMS = 'sms',
  /** 邮件 */
  Email = 'email',
  /** Facebook */
  Facebook = 'facebook',
  /** Twitter */
  Twitter = 'twitter',
  /** LinkedIn */
  LinkedIn = 'linkedin',
  /** Instagram */
  Instagram = 'instagram',
  /** WhatsApp */
  WhatsApp = 'whatsapp',
  /** Line */
  Line = 'line',
  /** Pinterest */
  Pinterest = 'pinterest',
  /** Pocket */
  Pocket = 'pocket',
  /** Dropbox */
  Dropbox = 'dropbox',
  /** VKontakte */
  VKontakte = 'vkontakte',
  /** KakaoTalk */
  Kakao = 'kakao',
  /** Tumblr */
  Tumblr = 'tumblr',
  /** Flickr */
  Flickr = 'flickr',
  /** 有道云笔记 */
  YouDaoNote = 'youdao_note',
  /** 印象笔记 */
  EverNote = 'evernote',
}

/** 所有有效平台值的联合类型 */
export type SharePlatform = `${Platform}`;

// ======================== 已下线平台常量 ========================
// 已停止服务或已下架的平台，保留兼容常量避免旧代码编译失败。
// 调用时原生层将返回 E_PLATFORM_UNSUPPORTED。

/** @deprecated Google+ 已停止服务 */
export const GooglePlus = 'google_plus';
/** @deprecated 人人网已停止服务 */
export const Renren = 'renren';
/** @deprecated 腾讯微博已停止服务 */
export const TencentWb = 'tencent_wb';
/** @deprecated 豆瓣已停止分享服务 */
export const Douban = 'douban';
/** @deprecated Facebook Messenger 已下线 */
export const FacebookMessenger = 'facebook_messenger';
/** @deprecated 易信已停止服务 */
export const Yixin = 'yixin';
/** @deprecated 易信朋友圈已停止服务 */
export const YixinCircle = 'yixin_circle';
/** @deprecated Foursquare 已停止分享支持 */
export const Foursquare = 'foursquare';
/** @deprecated 系统更多面板（使用 shareboard 替代） */
export const More = 'more';

/** 已下线平台集合，用于运行时检测 */
export const DEPRECATED_PLATFORMS: ReadonlySet<string> = new Set([
  GooglePlus,
  Renren,
  TencentWb,
  Douban,
  FacebookMessenger,
  Yixin,
  YixinCircle,
  Foursquare,
  More,
]);

/** 所有有效平台值的集合，用于运行时校验 */
export const VALID_PLATFORMS: ReadonlySet<string> = new Set(
  Object.values(Platform)
);

// ======================== 旧版数字 ID 兼容映射 ========================

/**
 * 旧版数字 ID (0~33) → 新字符串枚举映射
 *
 * 已下线平台映射到对应的 deprecated 常量字符串。
 * 调用方可通过 DEPRECATED_PLATFORMS.has(value) 判断是否已下线。
 *
 * @example
 * ```ts
 * const platform = LEGACY_PLATFORM_MAP[2]; // 'wechat_session'
 * ```
 */
export const LEGACY_PLATFORM_MAP: Readonly<Record<number, string>> = {
  0: Platform.QQ,
  1: Platform.Sina,
  2: Platform.WechatSession,
  3: Platform.WechatTimeline,
  4: Platform.QZone,
  5: Platform.Email,
  6: Platform.SMS,
  7: Platform.Facebook,
  8: Platform.Twitter,
  9: Platform.WechatFavorite,
  10: GooglePlus,            // @deprecated
  11: Renren,                // @deprecated
  12: TencentWb,             // @deprecated
  13: Douban,                // @deprecated
  14: FacebookMessenger,     // @deprecated
  15: Yixin,                 // @deprecated
  16: YixinCircle,           // @deprecated
  17: Platform.Instagram,
  18: Platform.Pinterest,
  19: Platform.EverNote,
  20: Platform.Pocket,
  21: Platform.LinkedIn,
  22: Foursquare,            // @deprecated
  23: Platform.YouDaoNote,
  24: Platform.WhatsApp,
  25: Platform.Line,
  26: Platform.Flickr,
  27: Platform.Tumblr,
  28: Platform.Alipay,
  29: Platform.Kakao,
  30: Platform.Dropbox,
  31: Platform.VKontakte,
  32: Platform.DingTalk,
  33: More,                  // @deprecated
};

/**
 * 将旧版数字 ID 转为新字符串枚举
 *
 * @param legacyId 旧版数字 ID（0~33）
 * @returns 新字符串枚举值，不存在则返回 undefined
 */
export function resolveLegacyPlatform(legacyId: number): string | undefined {
  return LEGACY_PLATFORM_MAP[legacyId];
}
