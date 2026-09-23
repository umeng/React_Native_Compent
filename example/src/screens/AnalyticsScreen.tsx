import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { UAnalytics } from 'umeng-react-native';

type LogEntry = { id: number; text: string };
let logId = 0;

export default function AnalyticsScreen(): React.JSX.Element {
  const [logs, setLogs] = useState<LogEntry[]>([]);

  const addLog = useCallback((text: string) => {
    setLogs((prev) => [{ id: ++logId, text }, ...prev].slice(0, 20));
  }, []);

  // ---- 自定义事件 ----

  const handleOnEvent = () => {
    UAnalytics.onEvent('test_event');
    addLog('onEvent("test_event")');
  };

  const handleOnEventWithLabel = () => {
    UAnalytics.onEventWithLabel('test_event', 'label_1');
    addLog('onEventWithLabel("test_event", "label_1")');
  };

  const handleOnEventWithMap = () => {
    UAnalytics.onEventWithMap('test_event', { key1: 'value1', key2: 'value2' });
    addLog('onEventWithMap("test_event", {key1, key2})');
  };

  const handleOnEventWithMapAndCount = () => {
    UAnalytics.onEventWithMapAndCount('test_event', { type: 'buy' }, 3);
    addLog('onEventWithMapAndCount("test_event", {type}, 3)');
  };

  const handleOnEventObject = () => {
    UAnalytics.onEventObject('test_event', { amount: 99.9, item: 'phone' });
    addLog('onEventObject("test_event", {amount, item})');
  };

  // ---- 页面统计 ----

  const handlePageStart = () => {
    UAnalytics.onPageStart('AnalyticsDemo');
    addLog('onPageStart("AnalyticsDemo")');
  };

  const handlePageEnd = () => {
    UAnalytics.onPageEnd('AnalyticsDemo');
    addLog('onPageEnd("AnalyticsDemo")');
  };

  const handlePageModeAuto = () => {
    UAnalytics.setPageCollectionModeAuto();
    addLog('setPageCollectionModeAuto()');
  };

  const handlePageModeManual = () => {
    UAnalytics.setPageCollectionModeManual();
    addLog('setPageCollectionModeManual()');
  };

  const handleReportError = () => {
    UAnalytics.reportError('test error from RN');
    addLog('reportError("test error from RN")');
  };

  // ---- 账号统计 ----

  const handleSignIn = () => {
    UAnalytics.profileSignInWithPUID('test_user_001');
    addLog('profileSignInWithPUID("test_user_001")');
  };

  const handleSignInWithProvider = () => {
    UAnalytics.profileSignInWithPUIDWithProvider('wechat', 'wx_user_001');
    addLog('profileSignInWithPUIDWithProvider("wechat", "wx_user_001")');
  };

  const handleSignOff = () => {
    UAnalytics.profileSignOff();
    addLog('profileSignOff()');
  };

  // ---- 超级属性 ----

  const handleSetCommonProperties = () => {
    UAnalytics.registerPreProperties({ app_version: '3.0.0', env: 'debug' });
    addLog('registerPreProperties({app_version, env})');
  };

  const handleGetPreProperties = async () => {
    try {
      const result = await UAnalytics.getPreProperties();
      addLog(`getPreProperties() → ${result}`);
      Alert.alert('超级属性', result);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`getPreProperties() ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  const handleClearPreProperties = () => {
    UAnalytics.clearPreProperties();
    addLog('clearPreProperties()');
  };

  const handleUnregisterPreProperty = () => {
    UAnalytics.unregisterPreProperty('env');
    addLog('unregisterPreProperty("env")');
  };

  // ---- 首次启动 ----

  const handleSetFirstLaunchEvent = () => {
    UAnalytics.setFirstLaunchEvent(['install', 'first_open']);
    addLog('setFirstLaunchEvent(["install", "first_open"])');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>自定义事件</Text>
      <View style={styles.buttonRow}>
        <Btn title="onEvent" onPress={handleOnEvent} />
        <Btn title="withLabel" onPress={handleOnEventWithLabel} />
        <Btn title="withMap" onPress={handleOnEventWithMap} />
      </View>
      <View style={styles.buttonRow}>
        <Btn title="withMapAndCount" onPress={handleOnEventWithMapAndCount} />
        <Btn title="eventObject" onPress={handleOnEventObject} />
      </View>

      <Text style={styles.sectionTitle}>页面统计</Text>
      <View style={styles.buttonRow}>
        <Btn title="PageStart" onPress={handlePageStart} />
        <Btn title="PageEnd" onPress={handlePageEnd} />
      </View>
      <View style={styles.buttonRow}>
        <Btn title="自动页面采集" onPress={handlePageModeAuto} />
        <Btn title="手动页面采集" onPress={handlePageModeManual} />
        <Btn title="上报错误" onPress={handleReportError} />
      </View>

      <Text style={styles.sectionTitle}>账号统计</Text>
      <View style={styles.buttonRow}>
        <Btn title="SignIn" onPress={handleSignIn} />
        <Btn title="SignIn+Provider" onPress={handleSignInWithProvider} />
        <Btn title="SignOff" onPress={handleSignOff} />
      </View>

      <Text style={styles.sectionTitle}>超级属性</Text>
      <View style={styles.buttonRow}>
        <Btn title="设置属性" onPress={handleSetCommonProperties} />
        <Btn title="获取属性" onPress={handleGetPreProperties} />
      </View>
      <View style={styles.buttonRow}>
        <Btn title="清除全部" onPress={handleClearPreProperties} />
        <Btn title="移除 env" onPress={handleUnregisterPreProperty} />
      </View>

      <Text style={styles.sectionTitle}>首次启动事件</Text>
      <View style={styles.buttonRow}>
        <Btn title="setFirstLaunchEvent" onPress={handleSetFirstLaunchEvent} />
      </View>

      <Text style={styles.sectionTitle}>调用日志</Text>
      <View style={styles.logContainer}>
        {logs.length === 0 ? (
          <Text style={styles.logEmpty}>点击按钮查看调用日志</Text>
        ) : (
          logs.map((log) => (
            <Text key={log.id} style={styles.logText}>
              {log.text}
            </Text>
          ))
        )}
      </View>
    </ScrollView>
  );
}

function Btn({ title, onPress }: { title: string; onPress: () => void }) {
  return (
    <TouchableOpacity style={styles.button} onPress={onPress} activeOpacity={0.7}>
      <Text style={styles.buttonText}>{title}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F6FA',
  },
  content: {
    padding: 16,
    paddingBottom: 32,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#333',
    marginTop: 16,
    marginBottom: 8,
  },
  buttonRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 4,
  },
  button: {
    backgroundColor: '#4A90D9',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 6,
  },
  buttonText: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '500',
  },
  logContainer: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    marginTop: 4,
    minHeight: 80,
  },
  logEmpty: {
    color: '#aaa',
    fontSize: 13,
    textAlign: 'center',
  },
  logText: {
    fontSize: 12,
    color: '#555',
    fontFamily: 'monospace',
    marginBottom: 4,
  },
});
