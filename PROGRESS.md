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

## [2025-12-22] iOS の簡易 Unity 管理実装を追加

### Context
Android 側に続き、iOS 側でも Unity を最小構成で管理できる実装を追加したい。

### Decision
- `UnityRuntime` を追加し、UnityFramework が存在する場合のみ起動・View 取得・メッセージ送信を行う。
- `ExpoUnityView` は Unity の rootView を貼り付けるだけの最小ビューに変更。
- `ExpoUnityViewModule` で `unityMessage` をイベント転送し、`sendUnityMessage` を UnitySendMessage 相当に実装。

### Alternatives
- 既存の Metal プレースホルダを維持: iOS で Unity 管理の説明ができないため不採用。
- UnityFrameworkWrapper を丸ごと移植: チュートリアルの粒度としては重いため簡易実装を採用。

### Consequences
- UnityFramework が存在しない環境でもビルド可能（`canImport(UnityFramework)` で無効化）。
- UnityFramework が組み込まれている場合は簡易的に Unity 画面が表示される。

### Checks
- `expo run:ios` でビルドできること（UnityFramework 未導入時もコンパイル可能）。

### Notes
- Unity → React のメッセージは `NativeCallProxy` 経由で `unityMessage` に転送。

## [2025-12-22] iOS UnityFrameworkWrapper Pod を導入

### Context
iOS の Unity ビルド成果物を `Unity` ディレクトリに集約し、Pod 経由で取り込めるようにしたい。

### Decision
- `UnityFrameworkWrapper` Pod を追加し、`Unity/UnityFramework.framework` と `Unity/Data` を取り込む構成に変更。
- `ExpoUnityView` 側は `UnityFrameworkWrapper` を依存追加し、`UnityRuntime` を同 Pod 内に移動。
- `UnityFrameworkWrapper/Unity` と `UnityFrameworkWrapper/Unity/Data` を `.keep` で保持。

### Alternatives
- Frameworks へ手動配置: 手順が属人化しやすいため不採用。

### Consequences
- Unity の iOS 出力先が `packages/expo-unity-view/ios/UnityFrameworkWrapper/Unity` に固定される。
- `pod install` 時に Data が Resources へコピーされる。

### Checks
- `pod install` が通ること。
- `expo run:ios` でビルドできること（UnityFramework 未配置ならリンクエラーになる）。

### Notes
- `scripts/patch-unity-library-ios.sh` は UnityFrameworkWrapper/Unity を参照する。

## [2025-12-22] iOS Unity ランタイムの生成/配置を make ios の前処理に追加

### Context
`UnityFrameworkWrapper` を導入したため、iOS の UnityFramework.framework + Data が未配置だとビルドが失敗する。

### Decision
- `scripts/ensure-unity-runtime-ios.sh` を追加し、Unity の iOS エクスポートから UnityFramework.framework と Data を生成・配置する。
- `make ios` の前処理として `ios-preprocess` を追加し、毎回自動で実行する。

### Alternatives
- 手動で UnityFramework.framework を配置: 手順漏れが起きやすいため不採用。

### Consequences
- iOS ビルド前に Unity export が無い場合はエラーになる（`UNITY_EXPORT_PATH` を設定する必要あり）。

### Checks
- `make ios` で `ensure-unity-runtime-ios.sh` が先に実行されること。

### Notes
- `UNITY_EXPORT_PATH` を Unity の iOS エクスポート先に設定して運用する。

## [2025-12-22] makefile の preprocess を Android/iOS に統一

### Context
`unity-patch` や iOS の Unity ランタイム生成など前処理が増えたため、`make` の入り口を統一して分かりやすくしたい。

### Decision
- `android-preprocess` と `ios-preprocess` を Makefile に追加し、`make android`/`make ios` はそれぞれの preprocess を先に実行する。
- iOS preprocess は `unity-patch` 実行後に `ensure-unity-runtime-ios.sh` を実行する。

### Alternatives
- `unity-patch` を直接 `android`/`ios` の前に書き続ける: 役割が増えるたびに複雑化するため不採用。

### Consequences
- 前処理の拡張が容易になり、`make` の流れが明確になる。

### Checks
- `make android`/`make ios` で preprocess が先に実行されること。

### Notes
- `android-preprocess` は現状 `unity-patch` のみで、将来拡張可能。

## [2025-12-22] iOS preprocess に Podfile パッチと pod install を追加

### Context
`UnityFrameworkWrapper` Pod を追加したが、Podfile に明示的に追加されず `import UnityFrameworkWrapper` が失敗した。

### Decision
- `scripts/patch-podfile-unity-runtime.sh` を追加して Podfile に `UnityFrameworkWrapper` を挿入。
- `ios-preprocess` で `pod install` を実行して依存を反映する。

### Alternatives
- Expo autolinking に任せる: local Pod 依存の解決ができないため不採用。

### Consequences
- `make ios` 実行時に Podfile が自動更新される。

### Checks
- `make ios` で Podfile に `UnityFrameworkWrapper` が追加され、ビルドが進むこと。

### Notes
- Podfile の target 名は `uaalforexpoexample` を前提に挿入する。

## [2025-12-22] iOS で Unity Data をアプリにコピーするビルドフェーズを追加

### Context
UnityFramework は組み込めたが、アプリ内に `Data/` がコピーされず `Data bundle not found` で起動に失敗した。

### Decision
- `patch-podfile-unity-runtime.sh` に `[CP-User] Copy Unity Data to App` を注入し、アプリの Resources に Data をコピーする。
- Data の参照元は `Pods/UnityFrameworkWrapper/Unity/Data` とローカルの `packages/.../Unity/Data` の両方を試す。

### Alternatives
- Podspec の script_phase のみでコピー: pod ターゲット内にコピーされるだけでアプリに入らないため不採用。

### Consequences
- iOS ビルド時に `Data/` が必ず app bundle に入る。

### Checks
- iOS アプリバンドルに `Data/` が存在すること。

### Notes
- ビルドフェーズ名は `[CP-User] Copy Unity Data to App`。

## [2025-12-22] UnityRuntime の iOS 公開プロトコル準拠エラー修正

### Context
iOS ビルドで `UnityFrameworkListener` の要件メソッドが `public` でないというエラーが発生した。

### Decision
- `UnityRuntime` の UnityFrameworkListener 実装メソッドを `public` に変更してアクセス制御エラーを解消する。

### Alternatives
- `UnityRuntime` を internal に戻す: Expo モジュール側からの利用に影響するため不採用。

### Consequences
- UnityFramework 側の公開プロトコルに準拠した実装となる。

### Checks
- iOS ビルドで `UnityFrameworkListener` の access control エラーが出ないこと。

### Notes
- UnityFramework のヘッダ警告（umbrella header）は警告のまま。

## [2025-12-22] iOS Unity Data のコピーをアプリターゲットに強制注入

### Context
Podfile の post_install で Unity Data のコピー用 build phase を追加しているが、Xcode プロジェクト側に反映されず `Data bundle not found` が継続。実際の app bundle に `Data/` が入っていない。

### Decision
- `scripts/ensure-unity-data-phase.rb` を追加し、`ios/uaalforexpoexample.xcodeproj` の app target に `[CP-User] Copy Unity Data to App` を直接付与する。
- `make ios-preprocess` で `pod install` 後にこのスクリプトを必ず実行する。

### Alternatives
- Podfile の post_install のみで完結: 実際の app target に反映されないケースがあるため不採用。

### Consequences
- iOS ビルド前に必ず app target に Data コピーの build phase が保証される。
- `Data/` が app bundle に入ることで Unity の初期化失敗を回避できる。

### Checks
- `ios/uaalforexpoexample.xcodeproj/project.pbxproj` に `[CP-User] Copy Unity Data to App` が存在すること。
- app bundle に `Data/` が生成されること。

### Notes
- xcodeproj gem を利用して build phase を追加する。

## [2025-12-22] Unity 色変更の RN UI を追加

### Context
Unity 画面に戻るボタンしかなく、React Native から Unity の見た目を操作できるサンプルが不足していた。

### Decision
- `unity-screen` に色変更ボタンを追加し、`sendUnityMessage` 経由で Unity の `ChangeColor` を呼び出す。
- Unity 側の `ColorController.ChangeColor` を public にして UnitySendMessage で呼び出せるようにする。

### Alternatives
- React 側の UI を追加せず、Unity 側のみで色変更: チュートリアル用途として操作性が低いため不採用。

### Consequences
- Unity の GameObject 名（`Cube`）とメソッド名（`ChangeColor`）に依存する。
- Unity export を更新する場合、スクリプトの public 変更が反映される。

### Checks
- Unity 画面で色ボタンを押すと Cube の色が変わること。

### Notes
- 送信する色は Unity 側で定義済みの `red/green/blue/yellow` に合わせた。

## [2025-12-22] Unity 送信メッセージを RN オーバーレイに表示

### Context
Unity 側から秒数（timer）メッセージが送られているが、React Native 側で可視化できていなかった。

### Decision
- `unity-screen` に Unity メッセージ表示テキストを追加し、`addUnityMessageListener` で最新メッセージを state に反映する。
- 表示位置は色ボタンと同じオーバーレイ領域（画面下）に配置する。

### Alternatives
- Toast やログのみ: 画面内で確認できないため不採用。

### Consequences
- Unity からの任意メッセージが UI に出るため、必要に応じてフォーマットやフィルタが必要になる可能性がある。

### Checks
- Unity の timer メッセージが RN の画面下に表示されること。

### Notes
- `unityMessage` の payload は現在文字列のみ。

## [2025-12-22] Android settings.gradle の :unityLibrary 参照を unity-patch で自動化

### Context
クローン環境で `:unityLibrary` の include が `android/settings.gradle` に入っておらず、`expo-unity-view` の依存解決に失敗した。

### Decision
`unity-patch` に settings.gradle のチェック/追記処理を追加し、未適用なら自動で `:unityLibrary` を include する。

### Alternatives
- 手動で settings.gradle を編集: クローンや prebuild の度に漏れやすいので不採用。

### Consequences
`unity-patch` 実行で Android プロジェクトの Unity 参照が必ず揃う。

### Checks
- `scripts/patch-unity-library.sh` 実行時に settings.gradle へ追記されること。

### Notes
- 追記先は `../packages/expo-unity-view/android/unityLibrary/unityLibrary`。

## [2025-12-22] Android Manifest の enableOnBackInvokedCallback 競合を unity-patch で自動解消

### Context
クローン環境で `android:enableOnBackInvokedCallback` の値が `app` と `unityLibrary` で競合し、manifest merger が失敗した。

### Decision
`unity-patch` に `android/app/src/main/AndroidManifest.xml` の自動パッチを追加し、`tools:replace="android:enableOnBackInvokedCallback"` と `xmlns:tools` を付与する。

### Alternatives
- 手動で manifest を編集: 再生成やクローン時に漏れやすいため不採用。

### Consequences
`unity-patch` 実行で manifest merge の競合が回避される。

### Checks
- `npm run android` で manifest merge エラーが出ないこと。

### Notes
- 既存の `tools:replace` がある場合は属性に追記する。

## [2025-12-22] make ios/android で preprocess を通しつつ引数を転送

### Context
`make ios`/`make android` で preprocess を通したいが、`--device` などの引数を npm スクリプトへ渡せなかった。

### Decision
`makefile` に `IOS_ARGS`/`ANDROID_ARGS` を追加し、`npm run ios`/`npm run android` を `-- $(IOS_ARGS)`/`-- $(ANDROID_ARGS)` で呼び出して引数を転送できるようにする。

### Alternatives
- `npm run ios -- --device "SK_iPhone"` を直接実行: preprocess を通したい要件に合わないため不採用。
- `make ios -- --device ...` で渡す: make の引数解釈によりターゲットとして扱われるため不採用。

### Consequences
`make ios IOS_ARGS='--device "SK_iPhone"'` のように変数で引数を渡せる。未指定時は従来どおり動作。

### Checks
- `make ios IOS_ARGS='--device "SK_iPhone"'` で preprocess が走った後に iOS 実行が開始されること。

### Notes
- 必要なら `ANDROID_ARGS` も同様に利用できる。

## [2025-12-22] ios-preprocess で Podfile 未生成時に prebuild を自動実行

### Context
クローン直後は `ios/Podfile` が存在せず、`ios-preprocess` の Podfile パッチが失敗する。

### Decision
`ios-preprocess` 内で `ios/Podfile` の存在をチェックし、無ければ `npx expo prebuild --clean --platform ios` を自動実行する。

### Alternatives
- 手動で prebuild を実行: 手順漏れが発生しやすいため不採用。

### Consequences
クローン直後でも `make ios` が前処理で止まりにくくなる。

### Checks
- `make ios-preprocess` が Podfile 未生成状態でも通ること。

### Notes
- prebuild が走るのは Podfile が無い場合のみ。
