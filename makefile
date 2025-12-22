.PHONY: prebuild android ios sync unity-patch android-preprocess ios-preprocess

prebuild:
	npm install
	npx expo prebuild --clean

sync:
	npm install
	cd packages/expo-unity-view && npm run build

unity-patch:
	./scripts/patch-unity-library.sh

android: android-preprocess
	npm run android

ios: ios-preprocess
	npm run ios

android-preprocess: unity-patch

ios-preprocess:
	$(MAKE) unity-patch
	./scripts/ensure-unity-runtime-ios.sh
	./scripts/patch-podfile-unity-runtime.sh ios/Podfile
	cd ios && LANG=en_US.UTF-8 pod install
	ruby ./scripts/ensure-unity-data-phase.rb
