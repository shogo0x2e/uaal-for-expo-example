.PHONY: prebuild android ios sync

prebuild:
	npm install
	npx expo prebuild --clean

sync:
	npm install
	cd packages/expo-unity-view && npm run build

android:
	npm run android

ios: 
	npm run ios
