// Reexport the native module. On web, it will be resolved to ExpoUnityViewModule.web.ts
// and on native platforms to ExpoUnityViewModule.ts
export { default } from './ExpoUnityViewModule';
export { default as ExpoUnityView } from './ExpoUnityView';
export * from  './ExpoUnityView.types';
