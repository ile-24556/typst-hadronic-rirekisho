// Font stacks (defaults)
#let fontSerif = ("New Computer Modern", "Hiragino Mincho ProN")
#let fontSan = ("Helvetica", "Hiragino Kaku Gothic ProN")
#let fontMono = "Menlo"

// Default sizes
#let systemFontSize = 8pt
#let nameFontSize = 16pt
#let inputFontSize = 10pt

// Japanese era table (descending order for lookup)
#let _eras = (
  (name: "令和", start: datetime(year: 2019, month: 5,  day: 1),  offset: 2018),
  (name: "平成", start: datetime(year: 1989, month: 1,  day: 8),  offset: 1988),
  (name: "昭和", start: datetime(year: 1926, month: 12, day: 25), offset: 1925),
  (name: "大正", start: datetime(year: 1912, month: 7,  day: 30), offset: 1911),
  (name: "明治", start: datetime(year: 1868, month: 1,  day: 25), offset: 1867),
)

// Convert datetime → 和暦 string (falls back to 西暦 if before 明治)
#let 和暦date(d) = {
  for era in _eras {
    if d >= era.start {
      return [#era.name#(d.year() - era.offset)年#d.month()月#d.day()日]
    }
  }
  [#d.year()年#d.month()月#d.day()日]
}

// Convert datetime → 西暦 string
#let 西暦date(d) = [#d.year()年#d.month()月#d.day()日]

// Runtime font/date state — updated by 履歴書設定, read via context
#let _san_font  = state("_san_font",   fontSan)
#let _mono_font = state("_mono_font",  fontMono)
#let _doc_date  = state("_doc_date",   datetime.today())
#let _date_style = state("_date_style", "和暦")  // "和暦" or "西暦"

// Internal: render a date using the current style (must be called inside context)
#let _format_date(d) = if _date_style.get() == "西暦" { 西暦date(d) } else { 和暦date(d) }

// Public: render a date that respects the date_style setting
#let 日付(d) = context _format_date(d)

// Title uses sans font from state
#let title = context text(
  font: _san_font.get(),
  tracking: 1em,
  size: 14pt,
  weight: "bold",
  [履歴書],
)

// Stroke constants
#let _outer = 1.5pt
#let _inner = 0.5pt
#let _dashed = stroke(thickness: 0.5pt, dash: "dashed")

#let email(address) = {
  set text(font: fontMono)
  if address != "" {
    link("mailto:" + address)[#address.replace(".", ".\u{200B}").replace("@", "@\u{200B}")]
  }
}

// 年月3列テーブルの共通実装
#let _年月テーブル(header_title, children) = {
  set text(size: inputFontSize)
  let _hi = (x: 0.5 * systemFontSize, y: 1.0 * systemFontSize)
  table(
    columns: (5em, 3em, 1fr),
    stroke: none,
    inset: (x: 0.5em, y: 1em),
    table.header(
      table.cell(stroke: (top: _outer, left: _outer, right: _inner, bottom: _inner), align: center, inset: _hi, text(
        size: systemFontSize,
      )[年]),
      table.cell(stroke: (top: _outer, left: none, right: _inner, bottom: _inner), align: center, inset: _hi, text(
        size: systemFontSize,
      )[月]),
      table.cell(stroke: (top: _outer, left: none, right: _outer, bottom: _inner), align: center, inset: _hi, text(
        size: systemFontSize,
      )[#header_title]),
    ),
    ..children,
  )
}

// エントリー行（学歴・職歴・資格共通）
#let _エントリー行(年, 月, 内容, bottom: _inner, align: left) = (
  table.cell(stroke: (top: none, left: _outer, right: _inner, bottom: bottom), align: center)[#年],
  table.cell(stroke: (top: none, left: none, right: _inner, bottom: bottom), align: center)[#月],
  table.cell(stroke: (top: none, left: none, right: _outer, bottom: bottom), align: align)[#h(5pt)#内容],
)

// セクションラベル行（学歴・職歴のみ使用）
#let _セクションラベル(label) = table.cell(
  colspan: 3,
  stroke: (top: none, left: _outer, right: _outer, bottom: _inner),
  align: center,
  inset: (x: 0.5 * systemFontSize, y: 1.0 * systemFontSize),
  text(size: systemFontSize)[#label],
)

// ── ドキュメント設定関数 ────────────────────────────────────
// Usage: #show: 履歴書設定.with(paper: "a4", margin: 1.5cm)
#let 履歴書設定(
  paper: "a4",
  margin: 1.5cm,
  font: fontSerif,
  sans_font: fontSan,
  mono_font: fontMono,
  base_size: 8pt,
  date: none,
  date_style: none,  // "和暦" or "西暦"; defaults to "和暦"
  body,
) = {
  set page(paper: paper, margin: margin)
  set text(font: font, size: base_size)
  _san_font.update(sans_font)
  _mono_font.update(mono_font)
  if date != none { _doc_date.update(date) }
  if date_style != none { _date_style.update(date_style) }
  body
}

// 基本情報ブロック
#let 基本情報(
  姓: "",
  名: "",
  姓読み: "",
  名読み: "",
  生年月日: "",
  年齢: 0,
  現住所: (:),
  連絡先: "",
  写真: none,
) = {
  show table: set block(breakable: true)
  set text(size: systemFontSize)

  let 郵便番号1 = 現住所.at("郵便番号", default: "")
  let 住所1 = 現住所.at("住所", default: "")
  let かな1 = 現住所.at("ふりがな", default: "")
  let 電話1 = 現住所.at("電話", default: "")
  let メール1 = 現住所.at("メール", default: "")

  // 連絡先の分解
  let 住所2     = if type(連絡先) == str { 連絡先 } else { 連絡先.at("住所",     default: "") }
  let かな2     = if type(連絡先) == dictionary { 連絡先.at("ふりがな", default: "") } else { "" }
  let 郵便番号2 = if type(連絡先) == dictionary { 連絡先.at("郵便番号", default: "") } else { "" }
  let 電話2     = if type(連絡先) == dictionary { 連絡先.at("電話",     default: "") } else { "" }
  let メール2   = if type(連絡先) == dictionary { 連絡先.at("メール",   default: "") } else { "" }

  let photo_width = 3cm
  let photo_height = 4cm
  let photo_frame_width = 1.25 * photo_width
  let photo_frame_height = 1.25 * photo_height

  // ── 全体を1つのgridにまとめる（2行 × 2列） ────────────────
  grid(
    columns: (1fr, photo_frame_width),
    column-gutter: 0pt,
    row-gutter: 0pt,
    align: top,

    // ────── 行1: 氏名テーブル ＋ 写真 ──────
    table(
      columns: (5em, 1fr, 1fr),
      rows: (10mm, 2em, 3 * nameFontSize, 3 * inputFontSize),
      // 合計 4cm で写真高さに合わせる
      stroke: none,
      inset: (x: 4pt, y: 3pt),
      table.cell(colspan: 3, grid(
        columns: (1fr, auto),
        title, grid.cell(align: bottom + right, context [#_format_date(_doc_date.get())現在]),
      )),
      // ふりがな行
      table.cell(stroke: (top: _outer, left: _outer, right: _inner, bottom: _dashed), align: center + horizon)[ふりがな],
      table.cell(stroke: (top: _outer, left: none, right: none, bottom: _dashed), align: center + horizon)[#姓読み],
      table.cell(stroke: (top: _outer, left: none, right: _outer, bottom: _dashed), align: start + horizon)[#名読み],
      // 氏名行
      table.cell(stroke: (top: none, left: _outer, right: _inner, bottom: _inner), align: center + horizon)[氏#h(1em)名],
      table.cell(stroke: (top: none, left: none, right: none, bottom: _inner), align: center + horizon)[
        #text(nameFontSize, 姓)
      ],
      table.cell(stroke: (top: none, left: none, right: _outer, bottom: _inner), align: start + horizon)[
        #text(nameFontSize, 名)
      ],
      // 生年月日行
      table.cell(stroke: (top: none, left: _outer, right: _inner, bottom: _inner), align: center + horizon)[生年月日],
      table.cell(colspan: 2, stroke: (top: none, left: none, right: _outer, bottom: _inner), align: horizon)[
        #h(2em)#text(inputFontSize, 生年月日) 生 #h(3em) (満 #h(0.5em) #年齢 歳)
      ],
    ),
    align(center + horizon,
      box(
        stroke: _dashed,
        height: photo_height,
        width: photo_width,
        if 写真 == none {
          align(center + horizon)[写真を貼る位置\(縦 40mm, 横 30mm)]
        } else {
          写真
        },
      )
    ),

    // ────── 行3: 住所 ＋ 電話・メール ──────
    table(
      columns: (4 * inputFontSize, 1fr),
      rows: (2em, 1em, 3 * inputFontSize),
      inset: (x: 4pt, y: 2pt),
      stroke: none,
      table.cell(stroke: (top: none, left: _outer, right: _inner, bottom: _dashed), align: center + horizon)[ふりがな],
      table.cell(stroke: (top: none, left: none, right: _inner, bottom: _dashed), align: center + horizon)[#かな1],
      table.cell(colspan: 2, stroke: (top: none, left: _outer, right: _inner, bottom: none), {
        pad(x: 0em, y: 0.5em, {if 郵便番号1 == "" { [現住所 (〒 #text(font: fontMono)[#box(width: 1.8em) - #h(2.4em)])] } else { [現住所 (〒 #text(font: fontMono, 郵便番号1))] }})
      }),
      table.cell(stroke: (top: none, left: _outer, right: none, bottom: _inner))[],
      table.cell(stroke: (top: none, left: none, right: _inner, bottom: _inner), align: center + horizon, text(size: inputFontSize, 住所1)),
    ),

    stack(
      table(
        columns: (1fr,),
        rows: 2em,
        stroke: none,
        inset: (x: 4pt, y: 3pt),
        table.cell(stroke: (top: _outer, left: none, right: _outer, bottom: _inner), align: horizon)[電話 #h(2em) #text(font: fontMono, 電話1)],
      ),
      table(
        columns: (1fr,),
        rows: (1em + 3 * inputFontSize,),
        stroke: none,
        inset: (x: 4pt, y: 3pt),
        table.cell(stroke: (top: none, left: none, right: _outer, bottom: _inner), {
          pad(x: 0em, y: 0em)[E-mail]
          context text(font: _mono_font.get(), size: 8pt, email(メール1))
        }),
      ),
    ),

    // ────── 行4: 連絡先 ＋ 連絡先電話・メール ──────
    table(
      columns: (4 * inputFontSize, 1fr),
      rows: (2em, 1em, 3 * inputFontSize),
      inset: (x: 4pt, y: 2pt),
      stroke: none,
      table.cell(stroke: (top: none, left: _outer, right: _inner, bottom: _dashed), align: center + horizon)[ふりがな],
      table.cell(stroke: (top: none, left: none, right: _inner, bottom: _dashed), align: center + horizon)[#かな2],
      table.cell(colspan: 2, stroke: (top: none, left: _outer, right: _inner, bottom: none), {
        pad(x: 0em, y: 0.5em, {if 郵便番号2 == "" { [連絡先 (〒 #text(font: fontMono)[#box(width: 1.8em)-#h(2.4em)])] } else { [連絡先 (〒 #text(font: fontMono, 郵便番号2))] }})
      }),
      table.cell(stroke: (top: none, left: _outer, right: none, bottom: _outer))[],
      table.cell(stroke: (top: none, left: none, right: _inner, bottom: _outer), align: center + horizon, text(size: inputFontSize, 住所2)),
    ),

    stack(
      table(
        columns: (1fr,),
        rows: 2em,
        stroke: none,
        inset: (x: 4pt, y: 3pt),
        table.cell(stroke: (top: _inner, left: none, right: _outer, bottom: _inner), align: horizon)[電話 #h(2em) #text(font: fontMono, 電話2)],
      ),
      table(
        columns: (1fr,),
        rows: (1em + 3 * inputFontSize,),
        stroke: none,
        inset: (x: 4pt, y: 3pt),
        table.cell(stroke: (top: none, left: none, right: _outer, bottom: _outer), {
          pad(x: 0em, y: 0em)[E-mail]
          context text(font: _mono_font.get(), size: 8pt, email(メール2))
        }),
      ),
    ),
  )
}

// ── 学歴・職歴ブロック ────────────────────────────────────────
#let 学歴職歴(学歴: (), 職歴: ()) = {
  show table: set block(breakable: true)
  let _map(arr, last_bottom: _outer) = arr.enumerate().map(pair => {
    let (i, e) = pair
    _エントリー行(
      e.年, e.月, e.内容,
      align: e.at("align", default: start),
      bottom: if i == arr.len() - 1 { last_bottom } else { _inner },
    )
  }).flatten()
  _年月テーブル(
    [学歴・職歴（各別にまとめて書く）],
    (
      _セクションラベル([学歴]),
      .._map(学歴, last_bottom: _inner),
      _セクションラベル([職歴]),
      .._map(職歴),
    ),
  )
}

// ── 資格欄ブロック ────────────────────────────────────────────
#let 資格欄(資格: ()) = {
  _年月テーブル(
    [免許・資格],
    資格.enumerate().map(pair => {
      let (i, e) = pair
      _エントリー行(
        e.年, e.月, e.内容,
        align: e.at("align", default: start),
        bottom: if i == 資格.len() - 1 { _outer } else { _inner },
      )
    }).flatten(),
  )
}

// ── 志望動機ブロック ─────────────────────────────────────────
#let 志望動機(height: 5cm, body) = {
  table(
    columns: (1fr,),
    rows: (height,),
    stroke: none,
    inset: (x: 5pt, y: 5pt),
    table.cell(stroke: (top: _outer, left: _outer, right: _outer, bottom: _outer), align: top)[
      #text(size: systemFontSize)[志望の動機、特技、好きな学科、アピールポイントなど]
      #linebreak()
      #set text(size: inputFontSize)
      #set par(first-line-indent: 1em)
      #v(0.75em, weak: true)
      #body
    ],
  )
}

// ── 本人希望ブロック ─────────────────────────────────────────
#let 本人希望(height: 5cm, body) = {
  table(
    columns: (1fr,),
    rows: (height,),
    stroke: none,
    inset: (x: 5pt, y: 5pt),
    table.cell(stroke: (top: _outer, left: _outer, right: _outer, bottom: _outer), align: top)[
      #text(size: systemFontSize)[本人希望記入欄（特に給料・職種・勤務時間・勤務地・その他についての希望があれば記入）]
      #linebreak()
      #set text(size: inputFontSize)
      #set par(first-line-indent: 1em)
      #v(0.75em, weak: true)
      #body
    ],
  )
}

// ── 賞罰ブロック ─────────────────────────────────────────────
#let 賞罰(エントリー: ()) = {
  _年月テーブル(
    [賞罰・処分歴等],
    エントリー.enumerate().map(pair => {
      let (i, e) = pair
      _エントリー行(
        e.年, e.月, e.内容,
        align: e.at("align", default: start),
        bottom: if i == エントリー.len() - 1 { _outer } else { _inner },
      )
    }).flatten(),
  )
}

// ── 署名欄ブロック ───────────────────────────────────────────
#let 署名欄(signature: none) = {
  set text(size: inputFontSize)
  table(
    columns: (1fr,),
    stroke: none,
    inset: (x: 5pt, y: 5pt),
    table.cell(stroke: (top: _outer, left: _outer, right: _outer, bottom: _outer), align: top)[
      本書類の記載内容については事実に相違なく、虚偽の記載があった場合には、採用取消や懲戒処分等の対象となりえることについて了承します。
      #v(0.5em)
      #context align(end, {
        let today = _doc_date.get()
        grid(
          columns: (auto, 0.5em, auto, 2em),
          align: left + horizon,
          row-gutter: 1em,
          grid.cell(colspan: 3)[#_format_date(today)], [],
          [氏名（自署）],
          [],
          if signature != none { box(signature) } else { h(5cm) },
          [],
        )
      })
      #v(0.5em)
    ],
  )
}
