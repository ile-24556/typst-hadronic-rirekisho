# typst-rirekisho

[Typst](https://typst.app/) で書く日本語履歴書テンプレート。

## ファイル構成

```
typst-rirekisho/
├── rirekisho.typ        # テンプレート本体
└── example/
    ├── example.typ      # 記入例（湯川秀樹）
    ├── example.pdf      # 記入例の出力
    ├── photo.jpg        # 証明写真（各自用意）
    └── signature.png    # 署名画像（各自用意）
```

---

## 設定（`履歴書設定`）

フォントや文字サイズなどの定数はすべて `履歴書設定` で一括指定でき、各ブロックに反映される。

```typst
#show: 履歴書設定.with(
  margin: 2.0cm,
  date: datetime(year: 1950, month: 3, day: 1),
  date_style: "和暦",
)
```

| パラメータ    | 型         | デフォルト             | 説明                                     |
|---------------|------------|------------------------|------------------------------------------|
| `paper`       | `str`      | `"a4"`                 | 用紙サイズ                               |
| `margin`      | `length`   | `1.5cm`                | ページ余白                               |
| `font`        | `array`    | 明朝体 (`fontSerif`)   | 本文フォント                             |
| `sans_font`   | `array`    | ゴシック体 (`fontSan`) | 見出し用フォント                         |
| `mono_font`   | `array`    | 等幅 (`fontMono`)      | 郵便番号・電話・メール用フォント         |
| `system_size` | `length`   | `8pt`                  | ラベル・枠見出しの文字サイズ             |
| `name_size`   | `length`   | `16pt`                 | 氏名の文字サイズ                         |
| `input_size`  | `length`   | `10pt`                 | 記入値の文字サイズ                       |
| `base_size`   | `length`   | `system_size`          | 本文の基本文字サイズ                     |
| `date`        | `datetime` | 今日                   | 履歴書の作成日                           |
| `date_style`  | `str`      | `"和暦"`               | 日付表示形式（`"和暦"` または `"西暦"`） |

---

## ブロック

### `#基本情報(...)`

氏名・生年月日・住所・写真を出力する。

```typst
#基本情報(
  姓: "山田", 名: "太郎",
  姓読み: "やまだ", 名読み: "たろう",
  生年月日: "昭和50年1月1日",
  年齢: 50,
  現住所: (
    郵便番号: "100-0001",
    住所: "東京都 千代田区 千代田 1番1号",
    ふりがな: "とうきょうと ちよだく ちよだ",
    電話: "090-0000-0000",
    メール: "taro@example.com",
  ),
  連絡先: "同上",  // または現住所と同じ形式の辞書
  写真: image("photo.jpg"),  // none で空欄
)
```

### `#学歴職歴(学歴: (...), 職歴: (...))`

学歴と職歴を一つのテーブルに出力する。

```typst
#学歴職歴(
  学歴: (
    (年: "平成10", 月: "4", 内容: "○○大学 △△学部 入学"),
    (年: "平成14", 月: "3", 内容: "○○大学 △△学部 卒業"),
  ),
  職歴: (
    (年: "平成14", 月: "4", 内容: "株式会社○○ 入社"),
    (年: "",       月: "",  内容: [以上#h(8em)], align: end),
  ),
)
```

### `#資格欄(資格: (...))`

免許・資格を出力する。エントリー形式は学歴職歴と同じ。

### `#志望動機(height: 5cm)[...]`

志望動機欄を出力する。`height` で欄の高さを指定する。

### `#本人希望(height: 5cm)[...]`

本人希望欄を出力する。`height` で欄の高さを指定する。

### `#賞罰(エントリー: (...))`

賞罰欄を出力する。エントリー形式は学歴職歴と同じ。

### `#署名欄(signature: none)`

署名欄を出力する。`signature` に画像を渡すと署名として表示する。

```typst
#署名欄(signature: image("signature.png", height: 1.0cm))
```

---

## 日付ユーティリティ

テンプレートには日付変換関数が含まれており、本文中でも使用できる。

| 関数 | 説明 |
|---|---|
| `和暦date(d)` | `datetime` → 和暦文字列（明治〜令和、それ以前は西暦） |
| `西暦date(d)` | `datetime` → 西暦文字列 |
| `日付(d)` | `date_style` 設定に従いどちらかで表示 |

```typst
// 和暦モード（デフォルト）
#日付(datetime(year: 1949, month: 10, day: 3))
// → 昭和24年10月3日

// 西暦モード（履歴書設定で date_style: "西暦" を指定した場合）
// → 1949年10月3日
```

---

## フォントについて

デフォルトフォントはクロスプラットフォームなフォールバックリストになっており、Linux (Noto)・Windows (游書体・Meiryo・MS 書体)・macOS (ヒラギノ) のいずれでもそのまま使える。

| 用途               | フォールバック順                                                                                |
|--------------------|-------------------------------------------------------------------------------------------------|
| 本文（明朝）       | New Computer Modern → Noto Serif CJK JP → Noto Serif JP → 游明朝 → ヒラギノ明朝 ProN → MS P明朝 |
| 見出し（ゴシック） | Noto Sans CJK JP → Noto Sans JP → 游ゴシック → Meiryo → ヒラギノ角ゴ ProN → MS Pゴシック        |
| 等幅               | DejaVu Sans Mono → Consolas → Menlo → Noto Sans Mono CJK JP                                     |

New Computer Modern と DejaVu Sans Mono は Typst 本体に同梱されているため、どの環境でも利用できる。コンパイル時に `unknown font family` の警告が出ることがあるが、これは環境にないフォールバック候補に対するもので、いずれかのフォントが見つかれば出力に問題はない。

フォントを固定したい場合は `履歴書設定` の `font`・`sans_font`・`mono_font` パラメータで指定する。

---

## 謝辞

このテンプレートは [Nikudanngo/typst-ja-resume-template](https://github.com/Nikudanngo/typst-ja-resume-template) を参考にして作成した。
