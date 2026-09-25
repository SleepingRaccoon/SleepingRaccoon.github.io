<#
.SYNOPSIS
  把 AI 生成的 Markdown 里常见的 LaTeX 写法，规范成本站能正确渲染的形式。

.DESCRIPTION
  AI 写文档时习惯用 \( \) 和 \[ \]，但这两种写法在 kramdown 里会被吃掉反斜杠
  （\(x\) 变成 (x)），到了网站上公式就成了裸文本。VS Code 的 Markdown 插件认这两种，
  所以经常出现"编辑器里好好的、网站上不渲染"。这个脚本负责把它统一到本站约定：

    * 行间公式 \[ ... \]（独占一行）→ $$ ... $$，并保证前后各有一个空行
    * 行内公式 \( ... \)        → $ ... $
    * kramdown 会吃掉的转义     → \{ \} 改写成 \lbrace \rbrace
    * 数学里的竖线              → |x| 改写成 \lvert x \rvert（GFM 会把含竖线的行当表格）
    * \left| \right|            → \left\lvert \right\rvert
    * 正文里的一级标题 #        → 删掉（页面标题由 front matter 的 title 渲染，不用手写）
    * 文件末尾补换行

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools/normalize-math.ps1 -Path "_radar/10_RDA_小斜视角.md"
  powershell -ExecutionPolicy Bypass -File tools/normalize-math.ps1 -Path "_radar" -Recurse
#>
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [switch]$Recurse,
  [switch]$WhatIfOnly
)

$utf8 = New-Object System.Text.UTF8Encoding($false)
$files = if ((Get-Item -LiteralPath $Path).PSIsContainer) {
  Get-ChildItem -LiteralPath $Path -Filter *.md -Recurse:$Recurse -File
} else {
  Get-Item -LiteralPath $Path
}

foreach ($file in $files) {
  $text = [IO.File]::ReadAllText($file.FullName)
  $text = $text -replace "`r`n", "`n"
  $original = $text

  # 1) 正文里的一级标题：页面标题由 front matter 渲染，留着会出现两个大标题
  $text = $text -replace '(?m)^#\s+.+\n', ''

  # 2) kramdown 会吃掉的转义
  $text = $text.Replace('\{', '\lbrace').Replace('\}', '\rbrace')
  $text = $text.Replace('\left|', '\left\lvert').Replace('\right|', '\right\rvert')

  # 3) 行间公式：独占一行的 \[ 和 \] 换成 $$
  $text = $text -replace '(?m)^[ \t]*\\\[[ \t]*$', '$$$$'
  $text = $text -replace '(?m)^[ \t]*\\\][ \t]*$', '$$$$'

  # 4) 行内公式：\( ... \) 换成 $ ... $
  $text = [regex]::Replace($text, '\\\((.*?)\\\)', { param($m) '$' + $m.Groups[1].Value.Trim() + '$' })

  # 5) 数学里的竖线：|x| → \lvert x \rvert（只处理含公式、且不是表格的行）
  $lines = $text -split "`n"
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*\|' -or $line -notmatch '\$') { continue }
    $parts = $line -split '\$'
    for ($k = 1; $k -lt $parts.Count; $k += 2) {
      $parts[$k] = [regex]::Replace($parts[$k], '\|([^|]+)\|', '\lvert $1 \rvert')
      # $...$ 里的 * 会被 kramdown 当成斜体标记插 <em>，公式随之失效（例如 \tau^{*}）
      $parts[$k] = $parts[$k].Replace('*', '\ast')
    }
    $lines[$i] = ($parts -join '$')
  }
  $text = $lines -join "`n"

  # 6) 块级公式前后各留一个空行
  $lines = $text -split "`n"
  $out = New-Object System.Collections.Generic.List[string]
  $inMath = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $cur = $lines[$i]
    if ($cur -eq '$$') {
      if (-not $inMath) {
        if ($out.Count -gt 0 -and $out[$out.Count - 1] -ne '') { $out.Add('') }
        $out.Add($cur); $inMath = $true
      } else {
        $out.Add($cur); $inMath = $false
        if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -ne '') { $out.Add('') }
      }
    } else { $out.Add($cur) }
  }
  $text = ($out -join "`n").TrimEnd("`n") + "`n"

  # 安全阀：正常改写只会增减少量字符，长度腰斩说明哪里出错了，宁可中止也不写坏原文
  if ($text.Trim().Length -lt ($original.Trim().Length * 0.5)) {
    throw "结果比原文短了一大截，已中止以避免写坏文件：$($file.FullName)"
  }

  if ($text -eq $original) {
    "跳过（已是规范写法）：$($file.Name)"
    continue
  }

  if ($WhatIfOnly) {
    "需要修改：$($file.Name)"
    continue
  }

  [IO.File]::WriteAllText($file.FullName, $text, $utf8)
  "已规范化：$($file.Name)"
}
