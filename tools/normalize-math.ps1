<#
.SYNOPSIS
  把 AI 生成的 Markdown 里的公式写法，统一成"网站和 VS Code 都能渲染"的形式。

.DESCRIPTION
  网站是 kramdown + MathJax，编辑器预览多半是 KaTeX，两边脾气不同，踩过的坑都固化在这里：

  定界符（统一成：行内 $x$，行间把 $$ 单独放一行）
    * \( \)            → $ $      （kramdown 会吃掉反斜杠，网站上变裸文本）
    * \[ \]（独占行）   → $$       （同上）
    * 行内的 $$x$$      → $x$      （KaTeX 系预览不认行内 $$）

  $...$ 里的字符会被 markdown 处理（$$ 块内不会），所以这些要改写：
    * \{ \}   → \lbrace \rbrace   （kramdown 会吃掉 \{）
    * |x|     → \lvert x \rvert    （GFM 把含竖线的行当表格）
    * *       → \ast              （当成强调标记插 <em>，公式直接废掉）
    * ' ''    → \prime            （智能引号会把撇号换成弯引号）

  另外会：
    * 修复控制字粘连（\lbracej、\rvertx 这类，LaTeX 命令名会一直往后读字母，KaTeX 直接报错）
    * 删掉正文里多余的一级标题（页面标题由 front matter 的 title 渲染）
    * 块级公式前后补空行；文件末尾补换行
    * 围栏代码块和行内代码里的内容一律不动

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

function Get-DangerousFix([string]$math) {
  if (-not $math) { return $math }
  $m = $math
  $m = $m.Replace('\{', '\lbrace ').Replace('\}', '\rbrace ')
  $m = $m.Replace('\left|', '\left\lvert ').Replace('\right|', '\right\rvert ')
  $m = [regex]::Replace($m, '\|([^|]+)\|', '\lvert $1 \rvert ')
  $m = $m.Replace('*', '\ast ')
  $m = $m.Replace("''", "\prime\prime ").Replace("'", "\prime ")
  return $m
}

$files = if ((Get-Item -LiteralPath $Path).PSIsContainer) {
  Get-ChildItem -LiteralPath $Path -Filter *.md -Recurse:$Recurse -File
} else {
  Get-Item -LiteralPath $Path
}

foreach ($file in $files) {
  $text = ([IO.File]::ReadAllText($file.FullName)) -replace "`r`n", "`n"
  $original = $text
  $lines = $text -split "`n"
  $inFence = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    # 围栏代码块直接跳过
    if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
    if ($inFence) { continue }

    # 行间定界符：独占一行的 \[ 和 \]
    if ($line -match '^\s*\\\[\s*$' -or $line -match '^\s*\\\]\s*$') {
      $line = '$$'
      $lines[$i] = $line
      continue
    }

    # 其余处理：反引号切分，偶数段是行内代码之外
    $segments = $line -split '`'
    for ($s = 0; $s -lt $segments.Count; $s += 2) {
      if (-not $segments[$s]) { continue }

      # 行内的 $$x$$ → $x$
      $segments[$s] = [regex]::Replace($segments[$s], '\$\$(.+?)\$\$', { param($m) '$' + $m.Groups[1].Value.Trim() + '$' })
      # 行内的 \( ... \) → $ ... $
      $segments[$s] = [regex]::Replace($segments[$s], '\\\((.*?)\\\)', { param($m) '$' + $m.Groups[1].Value.Trim() + '$' })

      # 控制字粘连修复
      $segments[$s] = [regex]::Replace($segments[$s], '\\(lbrace|rbrace|lvert|rvert|ast|prime)(?=[A-Za-z])', {
          param($m) '\' + $m.Groups[1].Value + ' '
        })

      # $...$ 内部不能出现的字符
      if ($segments[$s] -match '\$') {
        $parts = $segments[$s] -split '\$'
        for ($k = 1; $k -lt $parts.Count; $k += 2) {
          $parts[$k] = Get-DangerousFix $parts[$k]
        }
        $segments[$s] = ($parts -join '$')
      }
    }
    $lines[$i] = ($segments -join '`')
  }

  $text = $lines -join "`n"

  # 删掉正文里的一级标题
  $text = $text -replace '(?m)^#\s+.+\n', ''

  # 块级公式前后补空行（代码块内不动）
  $lines = $text -split "`n"
  $out = New-Object System.Collections.Generic.List[string]
  $inMath = $false
  $inFence2 = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $cur = $lines[$i]
    if ($cur -match '^\s*(```|~~~)') { $inFence2 = -not $inFence2; $out.Add($cur); continue }
    if ($inFence2) { $out.Add($cur); continue }
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

  # 安全阀：正常改写只会增减少量字符，长度腰斩说明出错了
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
