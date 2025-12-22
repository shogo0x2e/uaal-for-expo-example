import { Button, StyleSheet } from 'react-native';

import { Text, View } from '@/components/Themed';
import { useUnityBackdrop } from '@/hooks/use-unity-backdrop';
import { useRouter } from 'expo-router';
import { addUnityMessageListener, sendUnityMessage } from 'expo-unity-view';
import { useEffect, useState } from 'react';

export default function UnityScreen() {

  const router = useRouter();
  const { Backdrop } = useUnityBackdrop();
  const colors = ['red', 'green', 'blue', 'yellow'];
  const [unityMessage, setUnityMessage] = useState<string>('');

  useEffect(() => {
    const unsubscribe = addUnityMessageListener((event) => {
      setUnityMessage(event.message);
    });
    return () => unsubscribe();
  }, []);

  const onChangeColor = (color: string) => {
    sendUnityMessage({
      objectName: 'Cube',
      methodName: 'ChangeColor',
      message: color,
    });
  };

  return (
    <View style={styles.container}>
      <Backdrop />
      <View style={styles.controlPanel}>
        <Text style={styles.messageText}>{unityMessage || 'Unity timer: --'}</Text>
        <View style={styles.buttonGroup}>
          {colors.map((color) => (
            <View key={color} style={styles.buttonItem}>
              <Button title={`色: ${color}`} onPress={() => onChangeColor(color)} />
            </View>
          ))}
        </View>
        <Button
          title="戻る"
          onPress={() => {
            router.back();
          }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-end',
    paddingBottom: 24,
  },
  controlPanel: {
    width: '100%',
    maxWidth: 260,
  },
  messageText: {
    textAlign: 'center',
    marginBottom: 12,
    fontSize: 16,
    fontWeight: '600',
  },
  buttonGroup: {
    width: '100%',
  },
  buttonItem: {
    marginBottom: 8,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  separator: {
    marginVertical: 30,
    height: 1,
    width: '80%',
  },
});
