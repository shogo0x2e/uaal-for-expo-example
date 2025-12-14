import { registerWebModule, NativeModule } from 'expo';

import type {
  ExpoUnityViewModuleEvents,
  UnityOutgoingMessage,
} from './ExpoUnityView.types';

class ExpoUnityViewModule extends NativeModule<ExpoUnityViewModuleEvents> {
  async sendUnityMessage(message: UnityOutgoingMessage): Promise<void> {
    console.log('[ExpoUnityView:web] sendUnityMessage', message);
  }

  addUnityMessageListener() {
    // no-op for web mock; could emit test events here if desired
  }
}

export default registerWebModule(ExpoUnityViewModule, 'ExpoUnityViewModule');
