import { requireNativeView } from 'expo';
import * as React from 'react';
import { StyleSheet, View } from 'react-native';
import { ExpoUnityViewProps } from './ExpoUnityView.types';

const NativeView: React.ComponentType<ExpoUnityViewProps> =
  requireNativeView('ExpoUnityView');

export default function ExpoUnityView({ children }: ExpoUnityViewProps) {
  return (
    <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
      <NativeView style={StyleSheet.absoluteFill} />
      {children}
    </View>
  );
}
