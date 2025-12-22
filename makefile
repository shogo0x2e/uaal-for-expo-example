.PHONY: prebuild android ios sync unity-patch

prebuild:
	npm install
	npx expo prebuild --clean

sync:
	npm install
	cd packages/expo-unity-view && npm run build

unity-patch:
	./scripts/patch-unity-library.sh

android: unity-patch
	npm run android

ios: unity-patch
	npm run ios
