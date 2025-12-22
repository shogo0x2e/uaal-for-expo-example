import { Button, StyleSheet } from 'react-native';

import { View } from '@/components/Themed';
import { useUnityBackdrop } from '@/hooks/use-unity-backdrop';
import { useRouter } from 'expo-router';
import { sendUnityMessage } from 'expo-unity-view';

export default function UnityScreen() {

  const router = useRouter();
  const { Backdrop } = useUnityBackdrop();
  const colors = ['red', 'green', 'blue', 'yellow'];

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
