import { NativeModule, requireNativeModule } from 'expo';

import { ExpoUnityViewModuleEvents } from './ExpoUnityView.types';

declare class ExpoUnityViewModule extends NativeModule<ExpoUnityViewModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoUnityViewModule>('ExpoUnityView');
