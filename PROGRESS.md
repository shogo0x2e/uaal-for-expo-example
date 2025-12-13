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
