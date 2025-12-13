import * as React from 'react';

import { ExpoUnityViewProps } from './ExpoUnityView.types';

export default function ExpoUnityView(props: ExpoUnityViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
