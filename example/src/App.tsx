import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  Modal,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
  NativeModules,
  StatusBar,
  Platform,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

import { UPush } from 'umeng-react-native';
import AnalyticsScreen from './screens/AnalyticsScreen';
import PushScreen from './screens/PushScreen';
import ShareScreen from './screens/ShareScreen';
import APMScreen from './screens/APMScreen';

const Tab = createBottomTabNavigator();

const PRIVACY_KEY = 'privacy_accepted';

// 隐私合规桥接模块（Android 原生注册；iOS 上为 undefined，调用前需判空）
const UMConfigureModule = NativeModules.UMConfigureModule;

/**
 * 隐私政策弹窗组件
 */
function PrivacyModal({
  visible,
  onAccept,
  onReject,
}: {
  visible: boolean;
  onAccept: () => void;
  onReject: () => void;
}): React.JSX.Element {
  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      statusBarTranslucent
    >
      <View style={modalStyles.overlay}>
        <View style={modalStyles.container}>
          <Text style={modalStyles.title}>隐私政策</Text>
          <ScrollView style={modalStyles.scrollArea}>
            <Text style={modalStyles.content}>
              欢迎使用友盟+ React Native 示例应用。{'\n\n'}
              在使用本应用前，请您仔细阅读并同意以下隐私政策：{'\n\n'}
              1. 本应用使用友盟+ SDK 进行数据统计分析、消息推送、社交分享和性能监控。
              {'\n\n'}
              2. 友盟+ SDK 可能会收集设备信息（设备型号、操作系统版本等）、网络信息和应用使用数据。
              {'\n\n'}
              3. 所有收集的数据仅用于产品改进和服务优化，不会泄露给第三方。{'\n\n'}
              4. 您可以随时联系我们了解或删除已收集的数据。{'\n\n'}
              【注意】这是演示应用的模拟隐私政策流程，用于展示宿主应用应如何组织隐私交互。
              真实应用请根据实际合规要求制定隐私政策。
            </Text>
          </ScrollView>
          <View style={modalStyles.buttonRow}>
            <TouchableOpacity
              style={[modalStyles.button, modalStyles.rejectButton]}
              onPress={onReject}
              activeOpacity={0.7}
            >
              <Text style={modalStyles.rejectText}>不同意</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[modalStyles.button, modalStyles.acceptButton]}
              onPress={onAccept}
              activeOpacity={0.7}
            >
              <Text style={modalStyles.acceptText}>同意</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

/**
 * 受限页面 - 用户未同意隐私政策时显示
 */
function RestrictedScreen({
  onShowPolicy,
}: {
  onShowPolicy: () => void;
}): React.JSX.Element {
  return (
    <View style={restrictedStyles.container}>
      <Text style={restrictedStyles.icon}>🔒</Text>
      <Text style={restrictedStyles.title}>功能受限</Text>
      <Text style={restrictedStyles.message}>
        您尚未同意隐私政策，无法使用 SDK 功能。{'\n'}
        请同意隐私政策后再使用。
      </Text>
      <TouchableOpacity
        style={restrictedStyles.button}
        onPress={onShowPolicy}
        activeOpacity={0.7}
      >
        <Text style={restrictedStyles.buttonText}>查看隐私政策</Text>
      </TouchableOpacity>
    </View>
  );
}

export default function App(): React.JSX.Element | null {
  const [privacyAccepted, setPrivacyAccepted] = useState<boolean | null>(null);
  const [showModal, setShowModal] = useState(false);

  // 全局 Push 事件监听（必须在 initAfterConsent 之前注册，避免 "no listeners" 警告）
  useEffect(() => {
    const tokenSub = UPush.addEventListener('token', (token: string) => {
      console.log('[GlobalPush] DeviceToken:', token);
    });
    const openSub = UPush.addEventListener('notificationOpen', (msg: any) => {
      console.log('[GlobalPush] 通知点击:', JSON.stringify(msg));
    });
    const receiveSub = UPush.addEventListener('notificationReceive', (msg: any) => {
      console.log('[GlobalPush] 通知到达:', JSON.stringify(msg));
    });
    const messageSub = UPush.addEventListener('message', (msg: any) => {
      console.log('[GlobalPush] 透传消息:', JSON.stringify(msg));
    });
    return () => {
      tokenSub.remove();
      openSub.remove();
      receiveSub.remove();
      messageSub.remove();
    };
  }, []);

  useEffect(() => {
    // 启动时从 AsyncStorage 读取隐私政策同意状态
    AsyncStorage.getItem(PRIVACY_KEY)
      .then(async (value) => {
        if (value === 'true') {
          // 冷启动已同意：先触发原生正式初始化，再渲染功能页面
          if (UMConfigureModule?.initAfterConsent) {
            try {
              await UMConfigureModule.initAfterConsent();
            } catch (e) {
              console.warn('initAfterConsent failed on cold start', e);
            }
            // 推送注册由原生 initUmeng 完成（经 UMPushModule.registerFromNative）
          }
          setPrivacyAccepted(true);
        } else {
          setPrivacyAccepted(false);
          setShowModal(true);
        }
      })
      .catch(() => {
        setPrivacyAccepted(false);
        setShowModal(true);
      });
  }, []);

  const handleAccept = useCallback(async () => {
    await AsyncStorage.setItem(PRIVACY_KEY, 'true');
    // 用户同意：触发原生正式初始化（submitPolicyGrantResult + UMConfigure.init）
    if (UMConfigureModule?.initAfterConsent) {
      try {
        await UMConfigureModule.initAfterConsent();
      } catch (e) {
        console.warn('initAfterConsent failed', e);
      }
      // 推送注册由原生 initUmeng 完成（经 UMPushModule.registerFromNative）
    }
    setPrivacyAccepted(true);
    setShowModal(false);
  }, []);

  const handleReject = useCallback(() => {
    // 用户拒绝：通知原生提交授权结果（不执行 init）
    if (UMConfigureModule?.submitReject) {
      UMConfigureModule.submitReject().catch(() => {});
    }
    setShowModal(false);
    // 不初始化 SDK，保持受限状态
  }, []);

  const handleShowPolicy = useCallback(() => {
    setShowModal(true);
  }, []);

  // 加载状态期间显示 loading
  if (privacyAccepted === null) {
    return (
      <View style={restrictedStyles.container}>
        <ActivityIndicator size="large" color="#4A90D9" />
      </View>
    );
  }

  if (!privacyAccepted) {
    return (
      <View style={{ flex: 1 }}>
        <PrivacyModal
          visible={showModal}
          onAccept={handleAccept}
          onReject={handleReject}
        />
        {!showModal && <RestrictedScreen onShowPolicy={handleShowPolicy} />}
      </View>
    );
  }

  return (
    <>
    <StatusBar
      barStyle="light-content"
      backgroundColor="#4A90D9"
      translucent={false}
    />
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          headerStyle: { backgroundColor: '#4A90D9' },
          headerTintColor: '#fff',
          tabBarActiveTintColor: '#4A90D9',
          lazy: false,
        }}
      >
        <Tab.Screen
          name="Analytics"
          component={AnalyticsScreen}
          options={{
            title: '统计',
            tabBarIcon: ({ color }) => (
              <Text style={{ fontSize: 20, color }}>📊</Text>
            ),
          }}
        />
        <Tab.Screen
          name="Push"
          component={PushScreen}
          options={{
            title: '推送',
            tabBarIcon: ({ color }) => (
              <Text style={{ fontSize: 20, color }}>🔔</Text>
            ),
          }}
        />
        <Tab.Screen
          name="Share"
          component={ShareScreen}
          options={{
            title: '分享',
            tabBarIcon: ({ color }) => (
              <Text style={{ fontSize: 20, color }}>🔗</Text>
            ),
          }}
        />
        <Tab.Screen
          name="APM"
          component={APMScreen}
          options={{
            title: '性能',
            tabBarIcon: ({ color }) => (
              <Text style={{ fontSize: 20, color }}>⚡</Text>
            ),
          }}
        />
      </Tab.Navigator>
    </NavigationContainer>
    </>
  );
}

const modalStyles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  container: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    width: '100%',
    maxHeight: '80%',
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#333',
    textAlign: 'center',
    marginBottom: 16,
  },
  scrollArea: {
    maxHeight: 300,
    marginBottom: 20,
  },
  content: {
    fontSize: 14,
    lineHeight: 22,
    color: '#555',
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
  },
  button: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  rejectButton: {
    backgroundColor: '#F0F0F0',
  },
  acceptButton: {
    backgroundColor: '#4A90D9',
  },
  rejectText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#666',
  },
  acceptText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
  },
});

const restrictedStyles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F6FA',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  icon: {
    fontSize: 48,
    marginBottom: 16,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#333',
    marginBottom: 12,
  },
  message: {
    fontSize: 15,
    lineHeight: 24,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
  },
  button: {
    backgroundColor: '#4A90D9',
    paddingHorizontal: 32,
    paddingVertical: 12,
    borderRadius: 8,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
  },
});
