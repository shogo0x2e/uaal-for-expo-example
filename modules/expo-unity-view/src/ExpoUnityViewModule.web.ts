import { registerWebModule, NativeModule } from 'expo';

import { ExpoUnityViewModuleEvents } from './ExpoUnityView.types';

class ExpoUnityViewModule extends NativeModule<ExpoUnityViewModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoUnityViewModule, 'ExpoUnityViewModule');
