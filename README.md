# umeng-react-native

友盟+ React Native 桥接库，提供 **U-App 统计分析**、**U-Push 消息推送**、**U-Share 社会化分享**、**U-APM 性能监控** 四大模块的完整 TypeScript API。

基于 React Native 0.73 LTS + New Architecture（TurboModules）构建，支持 Android / iOS 双端。

## 目录

1. [环境要求](#环境要求)
2. [安装](#安装)
3. [初始化配置](#初始化配置)
4. [统计分析 (UAnalytics)](#统计分析-uanalytics)
5. [消息推送 (UPush)](#消息推送-upush)
6. [社会化分享 (UShare)](#社会化分享-ushare)
7. [性能监控 (UAPM)](#性能监控-uapm)
8. [隐私合规](#隐私合规)
9. [常见问题](#常见问题)
10. [版本说明](#版本说明)

---

## 环境要求

| 依赖 | 最低版本 |
|---|---|
| React Native | >= 0.73.0 |
| React | >= 18.0.0 |
| Node.js | >= 18 |
| Android compileSdk | 34 |
| Android minSdk | 23 |
| Android targetSdk | 34 |
| iOS Deployment Target | >= 13.0 |
| Xcode | >= 15.0 |
| CocoaPods | >= 1.13 |

---

## 安装

### 离线安装（.tgz）

本库当前通过离线 `.tgz` 方式分发，不发布到 npm。

```bash
# 1. 将 umeng-react-native-3.0.0.tgz 放到项目可访问的路径
# 2. 安装
npm install ./umeng-react-native-3.0.0.tgz
# 或
yarn add file:./umeng-react-native-3.0.0.tgz
```

### 本地路径安装（开发调试）

```bash
# package.json 中直接引用本地路径
{
  "dependencies": {
    "umeng-react-native": "file:../React_Native_Compent"
  }
}
```

### Android 配置

1. 确保项目 `android/build.gradle` 中 `compileSdk >= 34`、`minSdk >= 23`。

2. 在 `MainApplication.java` 的 `onCreate()` 中初始化友盟 SDK：

```java
import com.umeng.rn.RNUMConfigure;

@Override
public void onCreate() {
    super.onCreate();
    SoLoader.init(this, false);

    // 友盟 SDK 初始化
    // 参数：context, appKey, channel, logEnabled (1=开启, 0=关闭)
    RNUMConfigure.init(this, "YOUR_APPKEY", "YOUR_CHANNEL", 0);
}
```

> **完整初始化（含推送 Secret）：**
>
> ```java
> // 参数：context, appKey, channel, deviceType, pushSecret
> RNUMConfigure.init(this, "YOUR_APPKEY", "YOUR_CHANNEL",
>     UMConfigure.DEVICE_TYPE_PHONE, "YOUR_PUSH_SECRET");
> ```

3. TurboModule 会通过 `autolinking` 自动注册，无需手动添加 `ReactPackage`。

### iOS 配置

1. 安装 Pod 依赖：

```bash
cd ios && pod install
```

2. 在 `AppDelegate.mm` 中初始化友盟 SDK：

```objc
#import "RNUMConfigure.h"

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // 友盟 SDK 初始化
  [RNUMConfigure initWithAppkey:@"YOUR_APPKEY" channel:@"YOUR_CHANNEL"];

  // ... 其余初始化代码
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```

3. 如需使用 U-Share，请在 Xcode 中配置对应平台的 URL Scheme 和 Universal Link：
   - 微信：`wxYOUR_WECHAT_APPID`
   - QQ：`tencent YOUR_QQ_APPID`
   - 微博：`wb YOUR_SINA_APPKEY`

---

## 初始化配置

友盟 SDK 需要在**原生层**完成初始化，JS 层无需额外初始化调用。

### 隐私合规初始化流程

根据国内隐私法规要求，友盟 SDK 的初始化应在**用户同意隐私政策之后**进行：

```
App 启动
  ↓
展示隐私政策弹窗
  ↓
用户同意 → 调用原生初始化（RNUMConfigure.init）
用户拒绝 → 不初始化 SDK，限制功能
```

**Android 示例：**

```java
// 用户同意隐私政策后调用
RNUMConfigure.init(context, "YOUR_APPKEY", "YOUR_CHANNEL", 0);
```

**iOS 示例：**

```objc
// 用户同意隐私政策后调用
[RNUMConfigure initWithAppkey:@"YOUR_APPKEY" channel:@"YOUR_CHANNEL"];
```

> **注意：** 在用户同意隐私政策之前，请勿调用任何友盟 SDK 接口。`example/` 目录中包含完整的隐私政策弹窗模拟流程供参考。

---

## 统计分析 (UAnalytics)

提供自定义事件、页面统计、账号统计、超级属性等能力。

### 导入

```ts
import { UAnalytics } from 'umeng-react-native';
// 或按模块导入
// import * as UAnalytics from 'umeng-react-native/analytics';
```

### API 列表

#### 自定义事件

| 方法 | 说明 |
|---|---|
| `onEvent(eventId: string): void` | 计数事件 |
| `onEventWithLabel(eventId: string, label: string): void` | 带标签的计数事件 |
| `onEventWithMap(eventId: string, map: Record<string, string>): void` | 带属性的计数事件 |
| `onEventWithMapAndCount(eventId: string, map: Record<string, string>, count: number): void` | 带属性和数值的事件 |
| `onEventObject(eventId: string, map: Record<string, unknown>): void` | 带任意类型属性的事件 |

#### 页面统计

| 方法 | 说明 |
|---|---|
| `onPageStart(pageName: string): void` | 页面访问开始 |
| `onPageEnd(pageName: string): void` | 页面访问结束 |

#### 账号统计

| 方法 | 说明 |
|---|---|
| `profileSignInWithPUID(puid: string): void` | 账号登录（仅 PUID） |
| `profileSignInWithPUIDWithProvider(provider: string, puid: string): void` | 账号登录（含 Provider） |
| `profileSignOff(): void` | 账号登出 |

#### 超级属性（预置属性）

| 方法 | 说明 |
|---|---|
| `registerPreProperties(map: Record<string, unknown>): void` | 注册超级属性 |
| `unregisterPreProperty(propertyName: string): void` | 移除单个超级属性 |
| `getPreProperties(): Promise<string>` | 获取超级属性 ⚠️ **返回 Promise** |
| `clearPreProperties(): void` | 清除所有超级属性 |

#### 其他

| 方法 | 说明 |
|---|---|
| `setFirstLaunchEvent(eventList: string[]): void` | 设置首次启动事件列表 |

### 使用示例

```ts
import { UAnalytics } from 'umeng-react-native';

// 计数事件
UAnalytics.onEvent('click_buy');

// 带属性的事件
UAnalytics.onEventWithMap('purchase', { item: 'vip_month', price: '30' });

// 带属性和数值的事件
UAnalytics.onEventWithMapAndCount('payment', { method: 'alipay' }, 100);

// 页面统计
UAnalytics.onPageStart('ProductDetail');
// ... 页面展示 ...
UAnalytics.onPageEnd('ProductDetail');

// 账号统计
UAnalytics.profileSignInWithPUID('user_12345');
UAnalytics.profileSignOff();

// 超级属性
UAnalytics.registerPreProperties({ vip_level: 'gold', city: 'beijing' });
const props = await UAnalytics.getPreProperties(); // 返回 JSON 字符串
UAnalytics.unregisterPreProperty('city');
UAnalytics.clearPreProperties();

// 首次启动事件
UAnalytics.setFirstLaunchEvent(['first_open', 'first_tutorial']);
```

> ⚠️ **Breaking Change：** `getPreProperties()` 在旧版中通过 Callback 返回，3.0 改为 `Promise<string>`。

---

## 消息推送 (UPush)

提供 Tag / Alias 管理、推送注册、DeviceToken 获取等能力。

### 导入

```ts
import { UPush } from 'umeng-react-native';
```

### API 列表

#### Tag 管理

| 方法 | 说明 |
|---|---|
| `addTag(tag: string): Promise<Object>` | 添加 Tag |
| `deleteTag(tag: string): Promise<Object>` | 删除 Tag |
| `listTag(): Promise<Object>` | 获取 Tag 列表 |

#### Alias 管理

| 方法 | 说明 |
|---|---|
| `addAlias(alias: string, aliasType: string): Promise<Object>` | 添加 Alias |
| `addExclusiveAlias(alias: string, aliasType: string): Promise<Object>` | 设置排他 Alias（覆盖同类型旧值） |
| `deleteAlias(alias: string, aliasType: string): Promise<Object>` | 删除 Alias |

#### 注册与配置

| 方法 | 说明 |
|---|---|
| `register(): Promise<Object>` | 注册推送服务 |
| `getDeviceToken(): Promise<string>` | 获取 DeviceToken |

### 使用示例

```ts
import { UPush } from 'umeng-react-native';

// 注册推送
const result = await UPush.register();

// 获取 DeviceToken
const token = await UPush.getDeviceToken();
console.log('DeviceToken:', token);

// Tag 管理
await UPush.addTag('vip');
await UPush.deleteTag('trial');
const tags = await UPush.listTag();

// Alias 管理
await UPush.addAlias('user_123', 'custom_type');
await UPush.addExclusiveAlias('user_456', 'custom_type'); // 覆盖旧 alias
await UPush.deleteAlias('user_123', 'custom_type');
```

> ⚠️ **Breaking Change：** 所有 Tag/Alias 操作从 Callback 改为 `Promise`。

---

## 社会化分享 (UShare)

提供分享、授权、分享面板和平台配置能力，支持 28 个活跃平台。

### 导入

```ts
import { UShare } from 'umeng-react-native';
```

### API 列表

| 方法 | 说明 |
|---|---|
| `share(platform: string, shareParams?: ShareParams): Promise<ShareResult>` | 分享到指定平台 |
| `shareboard(shareParams?: ShareParams, platforms?: string[]): Promise<ShareResult>` | 弹出分享面板 |
| `auth(platform: string): Promise<AuthResult>` | 第三方平台授权登录 |

> 分享平台凭证（AppId/AppSecret）在**原生层**配置，不经 JS 桥接（避免凭证进入可解包提取的 JS bundle）。Android 用 `UMShareConfig` + `UMShareModule.init`，iOS 在 `AppDelegate` 调 `UMSocialManager setPlaform:`。

### 类型定义

```ts
interface ShareParams {
  text?: string;      // 分享文本
  img?: string;       // 图片路径或 URL
  webUrl?: string;    // 网页链接
  title?: string;     // 标题
}

interface ShareResult {
  code: number;       // 0=成功
  message: string;
}

interface AuthResult {
  code: number;       // 0=成功
  data: Record<string, string>; // uid, accessToken 等
  message: string;
}
```

### 平台枚举

使用 `Platform` 字符串枚举指定分享/授权平台：

```ts
import { UShare } from 'umeng-react-native';
const { Platform } = UShare;

// 或直接导入
// import { Platform } from 'umeng-react-native/share';
```

#### 活跃平台（28 个）

| 枚举值 | 字符串 | 说明 |
|---|---|---|
| `Platform.WechatSession` | `wechat_session` | 微信好友 |
| `Platform.WechatTimeline` | `wechat_timeline` | 微信朋友圈 |
| `Platform.WechatFavorite` | `wechat_favorite` | 微信收藏 |
| `Platform.QQ` | `qq` | QQ |
| `Platform.QZone` | `qzone` | QQ空间 |
| `Platform.Sina` | `sina` | 新浪微博 |
| `Platform.Alipay` | `alipay` | 支付宝 |
| `Platform.DingTalk` | `dingtalk` | 钉钉 |
| `Platform.WechatWork` | `wechat_work` | 企业微信 |
| `Platform.ByteDance` | `bytedance` | 抖音 |
| `Platform.ByteDanceFriends` | `bytedance_friends` | 抖音好友 |
| `Platform.SMS` | `sms` | 短信 |
| `Platform.Email` | `email` | 邮件 |
| `Platform.Facebook` | `facebook` | Facebook |
| `Platform.Twitter` | `twitter` | Twitter |
| `Platform.LinkedIn` | `linkedin` | LinkedIn |
| `Platform.Instagram` | `instagram` | Instagram |
| `Platform.WhatsApp` | `whatsapp` | WhatsApp |
| `Platform.Line` | `line` | Line |
| `Platform.Pinterest` | `pinterest` | Pinterest |
| `Platform.Pocket` | `pocket` | Pocket |
| `Platform.Dropbox` | `dropbox` | Dropbox |
| `Platform.VKontakte` | `vkontakte` | VKontakte |
| `Platform.Kakao` | `kakao` | KakaoTalk |
| `Platform.Tumblr` | `tumblr` | Tumblr |
| `Platform.Flickr` | `flickr` | Flickr |
| `Platform.YouDaoNote` | `youdao_note` | 有道云笔记 |
| `Platform.EverNote` | `evernote` | 印象笔记 |

#### 已下线平台（兼容常量）

以下平台已停止服务，保留常量避免旧代码编译失败，调用时返回 `E_PLATFORM_DEPRECATED` 错误：

| 常量 | 说明 |
|---|---|
| `GooglePlus` | Google+ 已停止服务 |
| `Renren` | 人人网已停止服务 |
| `TencentWb` | 腾讯微博已停止服务 |
| `Douban` | 豆瓣已停止分享服务 |
| `FacebookMessenger` | Facebook Messenger 已下线 |
| `Yixin` | 易信已停止服务 |
| `YixinCircle` | 易信朋友圈已停止服务 |
| `Foursquare` | Foursquare 已停止分享支持 |
| `More` | 系统更多面板（使用 `shareboard` 替代） |

#### 旧版数字 ID 兼容

3.0 以前使用数字 ID（0~33）标识平台。可通过 `resolveLegacyPlatform` 转换：

```ts
import { resolveLegacyPlatform, LEGACY_PLATFORM_MAP } from 'umeng-react-native/share';

const platform = resolveLegacyPlatform(2); // 'wechat_session'
```

### 使用示例

```ts
import { UShare } from 'umeng-react-native';

// 分享平台凭证在原生层配置（见上文说明），JS 侧无需设置

// 分享文本到微信
const result = await UShare.share(UShare.Platform.WechatSession, {
  text: '推荐给你一个好东西！',
  title: '分享标题',
  webUrl: 'https://example.com',
});
console.log(result.code === 0 ? '分享成功' : result.message);

// 弹出分享面板
const boardResult = await UShare.shareboard(
  { text: '分享内容', title: '标题' },
  [UShare.Platform.WechatSession, UShare.Platform.QQ, UShare.Platform.Sina]
);

// 第三方授权登录
const authResult = await UShare.auth(UShare.Platform.WechatSession);
if (authResult.code === 0) {
  console.log('uid:', authResult.data.uid);
  console.log('accessToken:', authResult.data.accessToken);
}
```

> ⚠️ **Breaking Change：** 平台标识从数字 ID 改为字符串枚举（如 `2` → `Platform.WechatSession`）。

---

## 性能监控 (UAPM)

提供自定义异常上报、自定义日志、启动/页面耗时埋点、自定义维度和版本管理能力。

> **新增模块**：UAPM 是 3.0 新增的模块，旧版不包含此功能。

### 导入

```ts
import { UAPM } from 'umeng-react-native';
```

### API 列表

#### 配置

> APM 配置（监控开关、App 版本）在**原生层**完成，不经 JS 桥接——因为 `UMCrash.initConfig` / `setAppVersion` 必须在 `UMConfigure.init` 之前执行才生效，而 JS 加载晚于原生初始化。
>
> - **Android**：在 `MainApplication` 中构造 `UMAPMConfig` 并调用 `UMAPMModule.init(this, config)`（须排在 `RNUMConfigure.init` 之前）。`UMAPMConfig` 字段：`crashAndBlockMonitorEnable`（崩溃与卡顿监控，统一开关，Android 内部同时写入 `KEY_ENABLE_CRASH_JAVA` / `CRASH_NATIVE` / `ANR` / `PA`）、`launchMonitorEnable`、`memMonitorEnable`、`networkEnable`、`pageMonitorEnable`、`logCollectEnable`、`javaScriptBridgeEnable`、`appVersion`、`buildVersion`。
> - **iOS**：在 `AppDelegate` 中通过 `UMCrashConfigure setAPMConfig:` 配置。

#### 异常上报

| 方法 | 说明 |
|---|---|
| `reportException(name: string, reason: string, stackTrace: string[]): void` | 上报自定义异常 |

#### 自定义日志

| 方法 | 说明 |
|---|---|
| `log(tag: string, message: string, level?: LogLevel): void` | 记录自定义日志 |

`LogLevel` 枚举：`Verbose`、`Debug`、`Info`（默认）、`Warn`、`Error`

#### 自定义维度

| 方法 | 说明 |
|---|---|
| `setCustomStringParam(key: string, value: string): void` | 设置自定义字符串参数 |

#### 启动耗时

| 方法 | 说明 |
|---|---|
| `beginLaunch(methodName: string): void` | 标记启动开始 |
| `endLaunch(methodName: string): void` | 标记启动结束 |

#### 页面耗时

| 方法 | 说明 |
|---|---|
| `beginPageTrace(methodName: string): void` | 标记页面加载开始 |
| `endPageTrace(methodName: string): void` | 标记页面加载结束 |

#### 版本设置

| 方法 | 说明 |
|---|---|
| `setAppVersion(appVersion: string, buildVersion: string): void` | 设置自定义 App 版本 |

### 使用示例

```ts
import { UAPM } from 'umeng-react-native';

// APM 配置在原生层完成（见上文「配置」说明），JS 侧无需调用

// 自定义异常上报
try {
  // 业务逻辑
} catch (error) {
  UAPM.reportException(
    'JsException',
    error.message,
    error.stack?.split('\n') ?? []
  );
}

// 自定义日志
UAPM.log('Network', '请求超时: /api/user', UAPM.LogLevel.Warn);
UAPM.log('Debug', '用户操作日志', UAPM.LogLevel.Debug);

// 自定义维度
UAPM.setCustomStringParam('user_type', 'vip');

// 启动耗时埋点
UAPM.beginLaunch('AppLaunch');
// ... 启动逻辑 ...
UAPM.endLaunch('AppLaunch');

// 页面耗时埋点
UAPM.beginPageTrace('ProductDetail');
// ... 页面加载 ...
UAPM.endPageTrace('ProductDetail');

// 自定义版本
UAPM.setAppVersion('2.1.0', '20260922');
```

---

## 隐私合规

友盟 SDK 遵循国内隐私法规要求，接入时请注意以下事项：

### 基本原则

1. **用户同意前置**：在用户明确同意隐私政策之前，不得初始化友盟 SDK，也不得调用任何数据采集接口。
2. **隐私政策披露**：在隐私政策中明确披露使用友盟 SDK 及其数据采集范围。
3. **个人信息收集清单**：按监管要求在 App 内提供第三方 SDK 收集个人信息的清单。

### 推荐接入流程

```
用户首次启动 App
  ↓
展示隐私政策弹窗（含友盟 SDK 信息披露）
  ↓
├── 用户同意
│     ↓
│   保存同意状态到本地
│     ↓
│   调用 RNUMConfigure.init(...) 初始化友盟 SDK
│     ↓
│   正常使用所有功能
│
└── 用户拒绝
      ↓
    不初始化友盟 SDK
      ↓
    限制相关功能（统计、推送、分享、APM 均不可用）
```

### Example 中的模拟实现

`example/` 目录包含完整的隐私政策模拟流程：

- 首次启动展示 `PrivacyModal` 弹窗
- 用户同意后通过 `AsyncStorage` 保存本地状态
- 后续启动读取状态后直接进入主页面
- 用户拒绝时停留在受限页面，可重新查看政策

> **注意：** Example 中的隐私流程仅为演示用途，不替代生产应用的合规方案。请结合自身业务需求和法律要求制定隐私策略。

---

## 常见问题

### 编译问题

**Q: Android 编译报错 `Namespace not specified`**

确保 `android/build.gradle` 中设置了 `namespace`：

```groovy
android {
    namespace "com.umeng.rn"
}
```

**Q: iOS pod install 失败**

1. 确认 Podfile 中设置了正确的平台版本：
   ```ruby
   platform :ios, '13.0'
   ```
2. 清理并重新安装：
   ```bash
   cd ios && rm -rf Pods Podfile.lock && pod install
   ```

**Q: iOS 编译报 `'UMCommon/UMCommon.h' file not found`**

确认已执行 `pod install` 且友盟 Pod 已正确安装。检查 Podfile.lock 中是否包含 `UMCommon`。

### 运行时问题

**Q: TurboModule 调用报 `TurboModuleRegistry: module not found`**

1. 确认 New Architecture 已启用。
2. Android：检查 `gradle.properties` 中 `newArchEnabled=true`。
3. iOS：检查 Podfile 中 `ENV['RCT_NEW_ARCH_ENABLED'] = '1'`。
4. 执行 `pod install` 后重新编译。

**Q: 分享/授权调用后无回调**

1. 确认已在原生层配置了对应平台的 AppKey/Secret。
2. iOS 需要配置 URL Scheme 和 Universal Link。
3. Android 需要确认 `onActivityResult` 正确传递。

**Q: 推送注册后无法收到推送**

1. 确认已在友盟后台正确配置推送证书（iOS）或 AppKey（Android）。
2. 调用 `UPush.register()` 后检查返回值。
3. 通过 `UPush.getDeviceToken()` 确认已获取到 DeviceToken。

**Q: `getPreProperties` 返回类型变了**

3.0 版本将 `getPreProperties` 从 Callback 改为 `Promise<string>`，需要使用 `await` 或 `.then()` 获取结果。

### 升级迁移

从旧版迁移到 3.0 的主要改动：

| 改动项 | 旧版 | 3.0 |
|---|---|---|
| 导入方式 | `import AnalyticsUtil from './AnalyticsUtil'` | `import { UAnalytics } from 'umeng-react-native'` |
| 分享平台标识 | 数字 ID（如 `2`） | 字符串枚举（如 `Platform.WechatSession`） |
| 推送/分享回调 | Callback | Promise |
| `getPreProperties` | Callback | `Promise<string>` |
| TypeScript | 不支持 | 完整类型定义 |
| APM 模块 | 无 | 新增 `UAPM` |

---

## 版本说明

### 3.0.0

- **架构升级**：React Native 0.73 LTS + New Architecture（TurboModules）
- **TypeScript 重构**：全面重构为 TypeScript，提供完整类型定义
- **新增 U-APM 模块**：支持自定义异常上报、自定义日志、启动/页面耗时埋点、自定义维度
- **分享平台改进**：平台标识从数字 ID 改为可读字符串枚举（`Platform.WechatSession` 等）
- **API 现代化**：所有 Callback 回调改为 Promise（`addTag`、`share`、`auth`、`getPreProperties` 等）
- **平台基线提升**：Android minSdk 23、iOS Deployment Target 13.0
- **仓库结构优化**：标准 RN 库形态（根目录桥接库 + `example/` 演示工程）
- **构建系统**：采用 `react-native-builder-bob` 输出 ESM + 类型定义

---

## 相关链接

- [友盟+ 开发者中心](https://developer.umeng.com/)
- [友盟+ SDK 下载中心](https://developer.umeng.com/sdk)
- [提交问题](https://github.com/umeng/React_Native_Compent/issues)
- [友盟开发者知识库](https://github.com/umeng/umeng-developer-guide)
