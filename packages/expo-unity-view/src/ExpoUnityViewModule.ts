import { NativeModule, requireNativeModule } from 'expo';

import type {
  ExpoUnityViewModuleEvents,
  UnityIncomingMessageEvent,
  UnityOutgoingMessage,
} from './ExpoUnityView.types';

declare class ExpoUnityViewModule extends NativeModule<ExpoUnityViewModuleEvents> {
  sendUnityMessage(message: UnityOutgoingMessage): Promise<void>;
  addUnityMessageListener(): void;
}

const nativeModule = requireNativeModule<ExpoUnityViewModule>('ExpoUnityView');

export function sendUnityMessage(message: UnityOutgoingMessage) {
  return nativeModule.sendUnityMessage(message);
}

export function addUnityMessageListener(handler: (event: UnityIncomingMessageEvent) => void) {
  const subscription = nativeModule.addListener('unityMessage', handler);
  nativeModule.addUnityMessageListener();
  return () => subscription.remove();
}

export default nativeModule;
