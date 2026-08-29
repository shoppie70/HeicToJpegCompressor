# ImageDrop

<p align="center">
  <img src="assets/ImageDrop.png" width="160" alt="ImageDrop app icon">
</p>

<p align="center">
  <strong>画像を、落とすだけ。</strong><br>
  JPEG変換、圧縮、リサイズだけを行うネイティブmacOSアプリです。
</p>

<p align="center">
  <a href="#はじめる">はじめる</a> · <a href="#使い方">使い方</a> · <a href="#主な機能">主な機能</a> · <a href="#ライセンス">ライセンス</a>
</p>

---

ImageDropは、HEIC・JPEG・PNGをWebで扱いやすいJPEGへ変換する、シンプルなmacOSアプリです。画像をアプリ画面またはDockアイコンへドロップすると、設定済みの品質・サイズで自動変換し、元ファイルと同じフォルダに保存します。

元画像を変更・上書きすることはありません。

> ただそれだけを行う、極めてシンプルなアプリです。機能が一つしか無いからこそ、便利です。

製品紹介ページは、GitHub Pagesで公開できます。GitHubリポジトリの **Settings → Pages → Build and deployment** で **GitHub Actions** を選択すると、`main` へのpush時に自動で更新されます。

## 主な機能

- **ドロップするだけ** — 複数の画像をまとめて変換。Convertボタンや保存ダイアログは不要です。
- **Web向けJPEG** — JPEG品質の初期値は0.85、最大長辺の初期値は1980pxです。
- **元画像を保護** — 出力は`IMG_1234_compressed.jpg`の形式で保存。同名ファイルがあれば連番を付けます。
- **プライバシー重視** — EXIF、GPS、カメラ情報、撮影日時などのmetadataを初期設定で削除します。
- **正しい向きで出力** — EXIF Orientationをピクセルへ正規化してからJPEG化します。
- **macOSネイティブ** — SwiftUI、ImageIO、Core Graphics、VisionなどApple標準フレームワークのみを使用しています。

## はじめる

現時点ではソースからビルドして利用できます。macOS 14以降とXcodeが必要です。

```bash
git clone https://github.com/shoppie70/ImageDrop.git
cd ImageDrop
open ImageDrop.xcodeproj
```

Xcodeで`ImageDrop`スキームを選び、`⌘R`で起動してください。Dockに追加したい場合は、ビルドされた`ImageDrop.app`を`/Applications`へコピーしてからDockへドラッグします。

## 使い方

1. ImageDropを起動します。
2. HEIC、HEIF、JPEG、JPG、PNGをアプリ画面へドロップします。
3. 元画像と同じフォルダに`_compressed.jpg`が作成されます。

最大長辺・JPEG品質はメイン画面下部から変更できます。metadata削除と自動回転は「詳細オプション」にあります。macOS標準のSettings（`⌘,`）からも同じ設定を変更できます。

## 変換の仕様

| 項目 | 内容 |
| --- | --- |
| 入力 | HEIC / HEIF / JPEG / JPG / PNG |
| 出力 | JPEG |
| JPEG品質 | 初期値 0.85 |
| 最大長辺 | 1280 / 1600 / 1980 / 2560 / 元のサイズ / 任意値 |
| リサイズ | アスペクト比を維持。小さい画像は拡大しない |
| 保存先 | 元画像と同じフォルダ |
| metadata | 初期設定で削除 |

## Orientationについて

EXIF Orientationは常に出力ピクセルへ焼き込み、metadataを削除しても正しい見た目を維持します。

オプションの自動補正ではVisionの水平線検出を利用し、明瞭な90度のずれだけを保守的に補正します。Vision APIには確度と180度の天地を安全に判定する情報がないため、180度の自動補正は行いません。曖昧な写真はそのまま出力します。

## 開発

```bash
swift test
xcodebuild -project ImageDrop.xcodeproj -scheme ImageDrop -configuration Debug build
```

変換ロジックはSwiftUI Viewから分離されており、リサイズ・ファイル名衝突・設定初期値・元ファイル保持・EXIF Orientation正規化をテストしています。

## ライセンス

ImageDropは[MIT License](LICENSE)のもとで公開されています。自由に利用、改変、再配布できます。
