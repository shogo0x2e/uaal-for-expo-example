import { Button, StyleSheet } from 'react-native';

import { View } from '@/components/Themed';
import { useUnityBackdrop } from '@/hooks/use-unity-backdrop';
import { useRouter } from 'expo-router';

export default function UnityScreen() {

  const router = useRouter();
  const { Backdrop } = useUnityBackdrop();

  return (
    <View style={styles.container}>
      <Backdrop />
      <Button
        title="戻る"
        onPress={() => {
          router.back();
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
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
