import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { UAPM } from 'umeng-react-native';

type LogEntry = { id: number; text: string };
let logId = 0;

export default function APMScreen(): React.JSX.Element {
  const [logs, setLogs] = useState<LogEntry[]>([]);

  const addLog = useCallback((text: string) => {
    setLogs((prev) => [{ id: ++logId, text }, ...prev].slice(0, 20));
  }, []);

  // ---- 异常上报 ----

  const handleReportException = () => {
    UAPM.reportException('JsException', 'render error', [
      'at App.render (App.tsx:42)',
      'at RenderRoot (react-dom.js:123)',
    ]);
    addLog('reportException("JsException", "render error", [...])');
  };

  const handleLog = () => {
    UAPM.log('APMDemo', 'debug message from RN', UAPM.LogLevel.Debug);
    addLog('log("APMDemo", "debug message", Debug)');
  };

  const handleLogError = () => {
    UAPM.log('APMDemo', 'error occurred in module X', UAPM.LogLevel.Error);
    addLog('log("APMDemo", "error occurred...", Error)');
  };

  // ---- 启动耗时 ----

  const handleBeginLaunch = () => {
    UAPM.beginLaunch('appColdStart');
    addLog('beginLaunch("appColdStart")');
  };

  const handleEndLaunch = () => {
    UAPM.endLaunch('appColdStart');
    addLog('endLaunch("appColdStart")');
  };

  // ---- 页面耗时 ----

  const handleBeginPageTrace = () => {
    UAPM.beginPageTrace('APMScreen');
    addLog('beginPageTrace("APMScreen")');
  };

  const handleEndPageTrace = () => {
    UAPM.endPageTrace('APMScreen');
    addLog('endPageTrace("APMScreen")');
  };

  // ---- 配置 ----

  // APM 配置（initConfig / setAppVersion）已移至原生 UMAPMModule.init()，
  // 确保在 UMConfigure.init 之前执行才生效；此处仅保留运行时自定义维度。
  const handleSetCustomParam = () => {
    UAPM.setCustomStringParam('env', 'debug');
    addLog('setCustomStringParam("env", "debug")');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>异常上报</Text>
      <View style={styles.buttonRow}>
        <Btn title="reportException" onPress={handleReportException} />
        <Btn title="log (Debug)" onPress={handleLog} />
        <Btn title="log (Error)" onPress={handleLogError} />
      </View>

      <Text style={styles.sectionTitle}>启动耗时</Text>
      <View style={styles.buttonRow}>
        <Btn title="beginLaunch" onPress={handleBeginLaunch} />
        <Btn title="endLaunch" onPress={handleEndLaunch} />
      </View>

      <Text style={styles.sectionTitle}>页面耗时</Text>
      <View style={styles.buttonRow}>
        <Btn title="beginPageTrace" onPress={handleBeginPageTrace} />
        <Btn title="endPageTrace" onPress={handleEndPageTrace} />
      </View>

      <Text style={styles.sectionTitle}>自定义维度</Text>
      <View style={styles.buttonRow}>
        <Btn title="setCustomParam" onPress={handleSetCustomParam} />
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
