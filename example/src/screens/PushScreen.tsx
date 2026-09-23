import React, { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { UPush } from 'umeng-react-native';

type LogEntry = { id: number; text: string };
let logId = 0;

export default function PushScreen(): React.JSX.Element {
  const [logs, setLogs] = useState<LogEntry[]>([]);

  const addLog = useCallback((text: string) => {
    setLogs((prev) => [{ id: ++logId, text }, ...prev].slice(0, 20));
  }, []);

  // 推送事件监听：token / 通知到达 / 通知点击 / 自定义消息
  // - Android：UMPushModule.register() 注册的 UmengNotificationClickHandler 与 message handler 触发
  // - iOS：AppDelegate 的 UNUserNotificationCenterDelegate 转发到 UMPushModule 静态入口触发
  //   （点击通知 → notificationOpen；前台收到 → notificationReceive；APNs 注册成功 → token）
  useEffect(() => {
    // iOS 注册成功后系统回调异步下发 deviceToken
    const tokenSub = UPush.addEventListener('token', (token: any) => {
      addLog(`[事件] 收到 DeviceToken: ${token}`);
    });

    // 用户点击通知（含冷启动由通知拉起），data 即通知的 userInfo / UMessage 内容
    const openSub = UPush.addEventListener('notificationOpen', (data: any) => {
      addLog(`[事件] 通知被点击: ${JSON.stringify(data)}`);
    });

    // 通知到达（iOS 前台收到通知 / 后台静默推送）
    const receiveSub = UPush.addEventListener(
      'notificationReceive',
      (data: any) => {
        addLog(`[事件] 收到通知: ${JSON.stringify(data)}`);
      }
    );

    // 自定义（透传）消息
    const msgSub = UPush.addEventListener('message', (data: any) => {
      addLog(`[事件] 收到消息: ${JSON.stringify(data)}`);
    });

    return () => {
      // addEventListener 返回 subscription 对象，通过 .remove() 取消监听
      tokenSub?.remove();
      openSub?.remove();
      receiveSub?.remove();
      msgSub?.remove();
    };
  }, [addLog]);

  // ---- 注册与 DeviceToken ----

  const handleRegister = async () => {
    try {
      await UPush.register();
      addLog('register() → 成功');
      Alert.alert('register', '注册推送成功');

      // Android：注册成功回调已缓存 registrationId，可立即获取
      // iOS：APNs token 由系统异步回调下发，此处可能为空，需依赖 token 事件
      const token = await UPush.getDeviceToken();
      if (token) {
        addLog(`DeviceToken: ${token}`);
      } else {
        addLog('DeviceToken 暂未获取到（iOS 需等待系统回调，可通过 token 事件监听）');
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`register ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  const handleGetDeviceToken = async () => {
    try {
      const token = await UPush.getDeviceToken();
      addLog(`getDeviceToken() → ${token}`);
      Alert.alert('getDeviceToken', token || '(空)');
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`getDeviceToken ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  // ---- Tag 管理 ----

  const handleAddTag = async () => {
    try {
      const result = await UPush.addTag('test_tag');
      addLog(`addTag("test_tag") → ${JSON.stringify(result)}`);
      Alert.alert('addTag', JSON.stringify(result));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`addTag ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  const handleDeleteTag = async () => {
    try {
      const result = await UPush.deleteTag('test_tag');
      addLog(`deleteTag("test_tag") → ${JSON.stringify(result)}`);
      Alert.alert('deleteTag', JSON.stringify(result));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`deleteTag ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  const handleListTag = async () => {
    try {
      const result = await UPush.listTag();
      addLog(`listTag() → ${JSON.stringify(result)}`);
      Alert.alert('listTag', JSON.stringify(result));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`listTag ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  // ---- Alias 管理 ----

  const handleAddAlias = async () => {
    try {
      const result = await UPush.addAlias('test_alias', 'custom');
      addLog(`addAlias("test_alias", "custom") → ${JSON.stringify(result)}`);
      Alert.alert('addAlias', JSON.stringify(result));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`addAlias ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  const handleAddExclusiveAlias = async () => {
    try {
      const result = await UPush.addExclusiveAlias('exclusive_alias', 'custom');
      addLog(
        `addExclusiveAlias("exclusive_alias", "custom") → ${JSON.stringify(result)}`
      );
      Alert.alert('addExclusiveAlias', JSON.stringify(result));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`addExclusiveAlias ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  const handleDeleteAlias = async () => {
    try {
      const result = await UPush.deleteAlias('test_alias', 'custom');
      addLog(
        `deleteAlias("test_alias", "custom") → ${JSON.stringify(result)}`
      );
      Alert.alert('deleteAlias', JSON.stringify(result));
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      addLog(`deleteAlias ERROR: ${msg}`);
      Alert.alert('Error', msg);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>注册与 DeviceToken</Text>
      <View style={styles.buttonRow}>
        <Btn title="注册推送" onPress={handleRegister} />
        <Btn title="获取 DeviceToken" onPress={handleGetDeviceToken} />
        <Btn title="打开通知设置" onPress={() => UPush.openNotificationSettings()} />
        <Btn title="通知权限状态" onPress={async () => {
          try {
            const enabled = await UPush.isNotificationEnabled();
            addLog(`通知权限: ${enabled ? '已开启' : '未开启'}`);
            Alert.alert('通知权限', enabled ? '已开启' : '未开启');
          } catch (e: any) {
            addLog(`isNotificationEnabled ERROR: ${e.message}`);
          }
        }} />
      </View>

      <Text style={styles.sectionTitle}>Tag 管理</Text>
      <View style={styles.buttonRow}>
        <Btn title="addTag" onPress={handleAddTag} />
        <Btn title="deleteTag" onPress={handleDeleteTag} />
        <Btn title="listTag" onPress={handleListTag} />
      </View>

      <Text style={styles.sectionTitle}>Alias 管理</Text>
      <View style={styles.buttonRow}>
        <Btn title="addAlias" onPress={handleAddAlias} />
        <Btn title="exclusiveAlias" onPress={handleAddExclusiveAlias} />
        <Btn title="deleteAlias" onPress={handleDeleteAlias} />
      </View>

      <Text style={styles.sectionTitle}>调用日志</Text>
      <Text style={styles.hint}>
        已监听 token / notificationOpen / notificationReceive / message
        四类事件；点击推送后回调内容会打印在下方。
      </Text>
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
  hint: {
    color: '#8A8F98',
    fontSize: 12,
    lineHeight: 18,
    marginBottom: 8,
  },
  logText: {
    fontSize: 12,
    color: '#555',
    fontFamily: 'monospace',
    marginBottom: 4,
  },
});
