<#
.SYNOPSIS
  把 AI 生成的 Markdown 里常见的 LaTeX 写法，规范成"网站和编辑器都能渲染"的形式。

.DESCRIPTION
  两个环境对公式的脾气不一样，踩过的坑都固化在这里了：

  1) 冲突的行内定界符
     * \( \) 和 \[ \]：VS Code 的插件认，但 kramdown 会把反斜杠吃掉，网站上公式变裸文本。
     * 行内 $$x$$：kramdown 认（当行内），但 KaTeX 系预览（VS Code 内置预览等）只认 $x$，
       会把 $$x$$ 当成行间公式或干脆不渲染。
     => 统一成：行内用 $x$，行间用单独占一行的 $$。

  2) $...$ 里的字符会被 markdown 处理（$$...$$ 块内不会），所以这些要改写：
     * \{ \}   → \lbrace \rbrace（kramdown 会吃掉 \{
     * |x|     → \lvert x \rvert（GFM 会把含竖线的行当表格）
     * *       → \ast（会被当成强调标记，插进 <em>，公式直接废掉）
     * ' ''    → \prime \prime\prime（智能引号会把 ' 换成弯引号）
     注意：控制字后面必须跟空格或花括号，否则会和后面的字母粘成一个不存在的命令
     （例如 \exp\{j → \exp\lbracej，KaTeX 会报 undefined control sequence）。

  3) 其它清理：删掉正文里多余的一级标题；块级公式前后补空行；文件末尾补换行。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools/normalize-math.ps1 -Path "_radar/05_Keystone变换.md"
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

  # --- 1) 正文里的一级标题：页面标题由 front matter 的 title 渲染 ---
  $text = $text -replace '(?m)^#\s+.+\n', ''

  # --- 2) 行内 $$x$$ → $x$（只处理同一行内成对的，独占一行的 $$ 是行间定界符，保持不动）---
  $lines = $text -split "`n"
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line.Trim() -eq '$$') { continue }
    $line = [regex]::Replace($line, '\$\$(.+?)\$\$', { param($m) '$' + $m.Groups[1].Value.Trim() + '$' })
    $lines[$i] = $line
  }
  $text = $lines -join "`n"

  # --- 3) 行间定界符 \[ \] → $$（\( \) 稍后按行内处理）---
  $text = $text -replace '(?m)^[ \t]*\\\[[ \t]*$', '$$$$'
  $text = $text -replace '(?m)^[ \t]*\\\][ \t]*$', '$$$$'

  # --- 4) 行内 \( ... \) → $ ... $ ---
  $text = [regex]::Replace($text, '\\\((.*?)\\\)', { param($m) '$' + $m.Groups[1].Value.Trim() + '$' })

  # --- 4b) 修复控制字粘连：LaTeX 里 \lbracej、\rvertx、\astj 这类一定是写错，
  #         因为命令名会一直往后读字母。这里在控制字和后续字母之间补一个空格。---
  $text = [regex]::Replace($text, '\\(lbrace|rbrace|lvert|rvert|ast|prime)(?=[A-Za-z])', {
      param($m) '\' + $m.Groups[1].Value + ' '
    })

  # --- 5) $...$ 里不能出现的字符（含表格行：竖线在表格里是分隔符，但表格单元格内的 $...$ 仍需处理）---
  $lines = $text -split "`n"
  $inMathBlock = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line.Trim() -eq '$$') { $inMathBlock = -not $inMathBlock; continue }
    if ($inMathBlock) { continue }   # 行间公式内容由 kramdown 原样保留，不用改写
    if ($line -notmatch '\$') { continue }

    $parts = $line -split '\$'
    for ($k = 1; $k -lt $parts.Count; $k += 2) {
      $m = $parts[$k]
      if (-not $m) { continue }
      $m = $m.Replace('\{', '\lbrace ').Replace('\}', '\rbrace ')
      $m = $m.Replace('\left|', '\left\lvert ').Replace('\right|', '\right\rvert ')
      $m = [regex]::Replace($m, '\|([^|]+)\|', '\lvert $1 \rvert ')
      $m = $m.Replace('*', '\ast ')
      $m = $m.Replace("''", "\prime\prime ")
      $m = $m.Replace("'", "\prime ")
      $parts[$k] = $m
    }
    $lines[$i] = ($parts -join '$')
  }
  $text = $lines -join "`n"

  # --- 6) 块级公式前后各留一个空行 ---
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

  # --- 7) 安全阀：正常改写只会增减少量字符，长度腰斩说明哪里出错了 ---
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
