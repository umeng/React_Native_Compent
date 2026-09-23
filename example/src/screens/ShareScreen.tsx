import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { UShare } from 'umeng-react-native';

const { Platform } = UShare;

type LogEntry = { id: number; text: string };
let logId = 0;

/** 演示用平台列表 */
const DEMO_PLATFORMS = [
  { label: '微信', value: Platform.WechatSession },
  { label: '朋友圈', value: Platform.WechatTimeline },
  { label: 'QQ', value: Platform.QQ },
  { label: 'QQ空间', value: Platform.QZone },
  { label: '微博', value: Platform.Sina },
  { label: '钉钉', value: Platform.DingTalk },
] as const;

export default function ShareScreen(): React.JSX.Element {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [selectedPlatform, setSelectedPlatform] = useState(Platform.WechatSession);

  const addLog = useCallback((text: string) => {
    setLogs((prev) => [{ id: ++logId, text }, ...prev].slice(0, 20));
  }, []);

  // ---- 分享 ----

  const handleShare = async () => {
    addLog(`share("${selectedPlatform}", {...})`);
    try {
      const result = await UShare.share(selectedPlatform, {
        title: 'Umeng RN Demo',
        text: '友盟 React Native 分享测试',
        webUrl: 'https://www.umeng.com',
        img: 'https://img.alicdn.com/imgextra/i4/O1CN014bpLZk1YbJR4qVmxq_!!6000000003077-0-tps-100-100.jpg',
      });
      addLog(`  → code=${result.code} msg=${result.message}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`  → ERROR: ${msg}`);
    }
  };

  // ---- 分享面板 ----

  const handleShareboard = async () => {
    const platforms = [
      Platform.WechatSession,
      Platform.WechatTimeline,
      Platform.QQ,
      Platform.QZone,
      Platform.Sina,
    ];
    addLog(`shareboard({...}, [${platforms.length} platforms])`);
    try {
      const result = await UShare.shareboard(
        {
          title: 'Umeng RN Demo',
          text: '友盟 React Native 分享面板测试',
          webUrl: 'https://www.umeng.com',
          img: 'https://img.alicdn.com/imgextra/i4/O1CN014bpLZk1YbJR4qVmxq_!!6000000003077-0-tps-100-100.jpg',
        },
        platforms
      );
      addLog(`  → code=${result.code} msg=${result.message}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`  → ERROR: ${msg}`);
    }
  };

  // ---- 授权登录 ----

  const handleAuth = async () => {
    addLog(`auth("${selectedPlatform}")`);
    try {
      const result = await UShare.auth(selectedPlatform);
      const dataStr = JSON.stringify(result.data || {}).slice(0, 100);
      addLog(`  → code=${result.code} data=${dataStr}`);
      Alert.alert('授权结果', JSON.stringify(result, null, 2));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`  → ERROR: ${msg}`);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>选择平台</Text>
      <View style={styles.platformGrid}>
        {DEMO_PLATFORMS.map((p) => (
          <TouchableOpacity
            key={p.value}
            style={[
              styles.platformChip,
              selectedPlatform === p.value && styles.platformChipActive,
            ]}
            onPress={() => setSelectedPlatform(p.value)}
            activeOpacity={0.7}
          >
            <Text
              style={[
                styles.platformChipText,
                selectedPlatform === p.value && styles.platformChipTextActive,
              ]}
            >
              {p.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.sectionTitle}>分享</Text>
      <View style={styles.buttonRow}>
        <Btn title="分享到选中平台" onPress={handleShare} />
        <Btn title="分享面板" onPress={handleShareboard} />
      </View>

      <Text style={styles.sectionTitle}>授权登录</Text>
      <View style={styles.buttonRow}>
        <Btn title="授权登录" onPress={handleAuth} />
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
  platformGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 4,
  },
  platformChip: {
    backgroundColor: '#E8EDF3',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: 'transparent',
  },
  platformChipActive: {
    backgroundColor: '#E3F0FF',
    borderColor: '#4A90D9',
  },
  platformChipText: {
    fontSize: 13,
    color: '#666',
  },
  platformChipTextActive: {
    color: '#4A90D9',
    fontWeight: '600',
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
