import * as React from 'react';

import { ExpoUnityViewProps } from './ExpoUnityView.types';

// Web fallback: just render children over a placeholder area.
export default function ExpoUnityView({ children }: ExpoUnityViewProps) {
  return (
    <div style={{ position: 'relative', width: '100%', height: '100%' }}>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: '#000', // placeholder surface
        }}
      />
      <div style={{ position: 'absolute', inset: 0 }}>{children}</div>
    </div>
  );
}
