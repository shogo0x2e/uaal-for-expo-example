import React, { useEffect } from 'react';
import { StyleSheet } from 'react-native';
import { useNavigation } from 'expo-router';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';

/**
 * Unity 画面用のバックドロップ。
 * 画面遷移中は黒で覆い、遷移完了後にフェードアウトする。
 */
export function useUnityBackdrop(duration: number = 220) {
  const navigation = useNavigation();
  const opacity = useSharedValue(1); // 1=黒, 0=透明

  useEffect(() => {
    opacity.value = 1;

    const off = navigation.addListener('transitionEnd' as never, (e: any) => {
      if (!e?.data?.closing) {
        opacity.value = withTiming(0, { duration });
      }
    });

    return () => {
      off && (off as () => void)();
    };
  }, [navigation, duration, opacity]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  const Backdrop: React.FC = () => (
    <Animated.View
      pointerEvents="none"
      style={[StyleSheet.absoluteFillObject, { backgroundColor: 'black' }, animatedStyle]}
    />
  );

  return { Backdrop };
}

export type UnityBackdropHook = ReturnType<typeof useUnityBackdrop>;
