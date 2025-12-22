## [2025-12-13] Android パッケージ名統一

### Context
Android ビルドで `com.uaalforexpoexample.BuildConfig` が見つからず失敗。`app.json` では `expo.android.package` が `com.shogo0x2e.uaalforexpoexample`、`android/app/build.gradle` では `com.shogokitada.uaalforexpoexample`、自動生成コードはデフォルトの `com.uaalforexpoexample` を参照しておりパッケージ名が分裂している。

### Decision
正規のパッケージ名を `com.shogo0x2e.uaalforexpoexample` に統一する。`android/app/build.gradle` の `namespace` と `applicationId` を揃え、Kotlin パッケージフォルダと `package` 宣言も同名に変更する。クリーンビルドで生成物を再作成する。

### Alternatives
- `com.shogokitada.uaalforexpoexample` を維持: ユーザー指定と異なるため不採用。
- デフォルトの `com.uaalforexpoexample` を維持: `app.json` と不一致で再発の恐れがあるため不採用。

### Consequences
ビルド生成物のパスが変わり、既存のデバッグ APK と署名が異なる可能性がある。旧パッケージ名を参照しているコードや設定が残っていると再度修正が必要。

### Checks
- `cd android && ./gradlew clean`
- `./gradlew :app:assembleDebug`（または Expo ルートから `npx expo run:android`）

### Notes
- オートリンク生成ファイルが旧パッケージを参照していた点を確認。
- MainApplication/MainActivity を Expo SDK 54 のテンプレート相当に再生成し、新パッケージ名に合わせた。
- RN 0.81 API に合わせて MainApplication/MainActivity を再調整（FeatureFlags の旧項目を削除し、新アーキ有効フラグの override を ReactNativeHostWrapper 側で指定、fabricEnabled 参照をプロパティに変更）。
- Autolinking が `com.uaalforexpoexample` を参照し続けるため、互換用 `android/app/src/main/java/com/uaalforexpoexample/BuildConfig.java` を追加し本来の BuildConfig をプロキシ。これで assembleDebug 成功（2025-12-13）。

## [2025-12-13] Unity モック表示コンポーネント設計（SurfaceView / CAMetalLayer）

### Context
本番 Unity 統合前に、`ExpoUnityView` を「Unity描画面の土台 + React オーバーレイ」だけに絞ったモックを作る。props は極力削り、`color` や `style` は不要。Unity の表示面をネイティブ側で確保し、その上に React 子要素を重ねられれば十分。

### Decision
- JS コンポーネントは `ExpoUnityView`（native view）と `children` オーバーレイの二層のみ。`children` を `StyleSheet.absoluteFillObject` で重ねる。
- props は `children` と `onReady?` のみ。`style` / `color` は提供しない。ネイティブ実体のサイズは親レイアウトで決める。
- Android: `SurfaceView` ベースの `ViewManager`。`surfaceCreated` 時に `onReady` イベントを送出し、Canvas 単色クリア程度のダミー描画（Unity 差し替え前提）。Surface は透明でなくデフォルトバッファを使用。
- iOS: `UIView` の `layerClass` を `CAMetalLayer` にし、`layoutSubviews` で初期化。`display()` で単色クリアする簡易レンダー。`onReady` を JS へ送る。
- Expo モジュール設定は既存 `expo-unity-view` のモジュール名に合わせ、イベント `onReady` だけエクスポート。その他 props なし。

### Alternatives
- React 側で `style` / `color` を持たせる: API をシンプルにしたいため不採用。
- TextureView (Android) や CAEAGLLayer (iOS) を使う: 将来 Unity 置き換え時の移行を考慮し、より近い SurfaceView / CAMetalLayer を採用。

### Consequences
- 親コンポーネントがサイズを決める必要がある。`style` を削ったことで固定サイズを JS から直指定はできないが、ラッパー View 経由で解決する想定。
- `onReady` 以外のイベントが無いので、将来の入力ハンドリング追加時は API 拡張が必要。

### Checks
- Android: `./gradlew :modules:expo-unity-view:assembleDebug` でビルド確認。
- iOS: `pod install` 後に `expo run:ios` で表示確認（単色描画と `onReady` 受信）。

### Notes
- オーバーレイは JS 側で `pointerEvents="box-none"` を適宜設定する想定。
- onReady コールバックは不要となったため削除方針。props は `children` のみ（2025-12-13 方針更新）。
- `ExpoUnityView` 実装を更新し、ネイティブビューを `StyleSheet.absoluteFill` + `pointerEvents="none"` で敷き、ラッパーを `pointerEvents="box-none"` にすることで React children を確実にオーバーレイできるようにした（2025-12-13）。
- Unity メッセージング API を設計反映: `sendUnityMessage` / `addUnityMessageListener` をネイティブモジュールに追加し、今はログ出力のみ（TODO: Unity 連携）。イベント名は `unityMessage` を予約（2025-12-13）。
- メッセージ型を向きで分割: Outgoing は `objectName`/`methodName`/`message` の UnitySendMessage 互換、Incoming は `message` 単体。JS 型と iOS/Android の関数シグネチャをこれに合わせてログのみ実装（2025-12-13）。
- `package.json` にローカルモジュール依存 `expo-unity-view: file:modules/expo-unity-view` を追加（2025-12-14）。
- 依存参照を `expo-unity-view: file:packages/expo-unity-view` に修正し、bundler で解決できるように戻した（2025-12-14）。
- ルート `package.json` に `workspaces: ["packages/*"]` を追加し、依存を `workspace:*` で解決するワークスペース運用に切り替え（2025-12-14）。
- Unity 画面用の遷移バックドロップ Hook `useUnityBackdrop` を追加し、`unity-screen` に適用。遷移完了時に黒→透明にフェード（2025-12-14）。

## [2025-12-22] Android Unity 管理シングルトン導入

### Context
チュートリアル向けに最小構成の Unity 管理を Kotlin 側へ実装し、Expo 側と統合して Android 実行まで確認できる状態にする。

### Decision
- `UnityManager`（シングルトン）を新設し、`UnityPlayerForActivityOrService` の生成・保持と View 取得、ライフサイクル呼び出しを一本化。
- `ExpoUnityView` は `UnityManager` を使って attach/detach と resume/pause を行うだけの最小実装に変更。
- Unity → React のメッセージ橋渡しとして `UnityToReactBridge.emitMessage` を追加し、Expo モジュールの `unityMessage` イベントへ転送。
- Android ビルドに `:unityLibrary` を組み込み、`unity-classes.jar` を依存に追加。

### Alternatives
- 既存の SurfaceView ダミー描画を維持: 実際の Unity 初期化を説明できないため不採用。
- Expo 側から明示的に `initializeUnity` を呼ぶ構成: チュートリアルの導線が増えるため不採用。

### Consequences
- `ExpoUnityView` を描画すると Unity が初期化されるため、Unity ネイティブライブラリが必須になる。
- Unity → React のメッセージはイベントリスナーが無い場合は破棄される（簡易実装）。

### Checks
- `npm run android` でビルド・起動確認。

### Notes
- `UnitySendMessage` は `sendUnityMessage` 経由で利用（Unity 側の GameObject/Method 名は JS 側で指定）。

## [2025-12-22] UnityLibrary 再生成に備えたパッチスクリプト追加

### Context
Unity の再ビルドで `unityLibrary` が再生成されるため、生成物に入れた修正が消えるリスクがある。Android/iOS 共通でパッチ適用の導線を確保したい。

### Decision
- `scripts/patch-unity-library.sh` を追加し、Unity エクスポート後に実行できるパッチ処理を一本化。
- Android は `unityLibrary/unityLibrary/build.gradle` に必要な設定を自動注入する。
- iOS は UnityLibrary が存在する場合の導線だけ先に用意し、パッチ内容は将来追加とした。
- Makefile に `unity:patch` を追加して運用を統一。

### Alternatives
- Unity 側テンプレートに埋め込む: 初期の手間が増えるため今回は保留。
- ルート gradle.properties に Unity 設定を複製: マシン依存パスが入りやすいため不採用。

### Consequences
- Unity 再生成後でもパッチ適用が可能になる。
- iOS はパッチ内容が決まるまでスクリプトは no-op になる。

### Checks
- `make unity:patch` が正常に実行できること。

### Notes
- `unity:patch` は `unity-patch` の別名として定義。

## [2025-12-22] android/ios 実行時に unity:patch を自動実行

### Context
手動で `unity:patch` を忘れると Unity 再生成後のビルドが壊れる可能性があるため、日常の `make android` / `make ios` に自動適用したい。

### Decision
- Makefile の `android` と `ios` ターゲットを `unity-patch` に依存させ、実行前に自動でパッチを当てるようにした。

### Alternatives
- README で手順を明記して手動運用: 手順漏れが起きやすいため不採用。

### Consequences
- `make android` / `make ios` 実行時に毎回パッチが走る（冪等で副作用なし）。

### Checks
- `make android` 実行時に `scripts/patch-unity-library.sh` が先に実行されること。

### Notes
- iOS 側のパッチは現状 no-op で、UnityLibrary が検出されると将来拡張可能。

## [2025-12-22] iOS パッチを別スクリプトへ分離

### Context
UnityLibrary の iOS 側パッチは内容が未確定だが、将来的に追加する前提で運用しやすくしておきたい。

### Decision
- `scripts/patch-unity-library-ios.sh` を新設し、iOS 側のパッチは別スクリプトで管理する。
- `scripts/patch-unity-library.sh` から iOS スクリプトを呼び出す方式に変更。

### Alternatives
- 既存スクリプト内に iOS ロジックを保持: 将来的な肥大化を避けるため不採用。

### Consequences
- iOS パッチの追加が独立して行える。
- iOS スクリプトが無い場合はスキップされる。

### Checks
- `make unity-patch` 実行時に iOS スクリプトが呼ばれること。

### Notes
- iOS 側パッチ内容は未定で、現状は no-op。
