import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoUnityViewProps } from './ExpoUnityView.types';

const NativeView: React.ComponentType<ExpoUnityViewProps> =
  requireNativeView('ExpoUnityView');

export default function ExpoUnityView(props: ExpoUnityViewProps) {
  return <NativeView {...props} />;
}
