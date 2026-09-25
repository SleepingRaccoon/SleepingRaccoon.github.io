<#
.SYNOPSIS
  体检：检查 Markdown 里的公式写法在"网站（kramdown + MathJax）"和"VS Code（KaTeX）"下是否会出问题。

.DESCRIPTION
  逐条检查这些已知会翻车的写法（围栏代码块与行内代码会跳过）：
    * 用了 \( \) 或 \[ \]        → kramdown 吃掉反斜杠，网站上变裸文本
    * 行内写了 $$x$$             → KaTeX 系预览不认
    * $...$ 里出现 \| \* ' \{ \} → 会被 markdown 改写（表格 / 斜体 / 弯引号 / 转义）
    * 控制字粘连 \lbracej 等      → LaTeX 命令名粘连，KaTeX 报 undefined control sequence
    * 一行里 $ 数量为奇数         → 定界符配对错乱

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools/check-math.ps1
#>
param([string]$Root = ".")

$files = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter *.md |
  Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Name -ne 'README.md' }

$problems = 0
$checked = 0

# 收集文档的线上路径，用于检查站内链接写没写对
$perm = @{}
foreach ($f in (Get-ChildItem -LiteralPath $Root -Recurse -File -Filter *.md | Where-Object { $_.FullName -notmatch '\\\.git\\' })) {
  $rel = $f.FullName.Substring((Resolve-Path -LiteralPath $Root).Path.Length).TrimStart('\', '/') -replace '\\', '/'
  if ($rel -like '_radar/*') { $perm['/radar/' + (($rel -replace '^_radar/', '') -replace '\.md$', '') + '/'] = $true }
  elseif ($rel -like '_cuda/*') { $perm['/cuda/' + (($rel -replace '^_cuda/', '') -replace '\.md$', '') + '/'] = $true }
  elseif ($rel -notlike '_*') { $perm['/' + ($rel -replace '\.md$', '') + '/'] = $true }
}

foreach ($file in $files) {
  $lines = ([IO.File]::ReadAllText($file.FullName)) -replace "`r`n", "`n" -split "`n"
  $inFence = $false
  $inMathBlock = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
    if ($inFence) { continue }
    if ($line -eq '$$') { $inMathBlock = -not $inMathBlock; continue }
    if ($inMathBlock) { continue }   # 行间公式内容不按 markdown 解析，不算问题

    # 去掉行内代码后逐段检查（代码里写的示例不算问题）
    $scan = $line
    $segments = $scan -split '`'
    for ($s = 0; $s -lt $segments.Count; $s += 2) {
      $seg = $segments[$s]
      if (-not $seg) { continue }

      # 裸 \prime（没写成上标）渲染出来位置不对
      if ($seg -match '(?<!\^\{)(?<!\\prime)((?:\\prime\s*)+)') {
        "  [$($file.Name):$($i + 1)] \prime 没写成上标，应为 ^{\prime}：$($seg.Trim())"; $problems++
      }

      # 站内链接：必须是绝对路径，且目标文档要存在
      foreach ($m in [regex]::Matches($seg, '\]\(([^)]+)\)')) {
        $target = $m.Groups[1].Value
        if ($target -match '^(https?:|mailto:|#)') { continue }
        if ($target -notmatch '^/') {
          "  [$($file.Name):$($i + 1)] 站内链接用了相对路径（会拼错）：$target"; $problems++
        }
        elseif ($target -match '^/(radar|cuda)/') {
          $clean = ($target -replace '#.*$', '') -replace '\?.*$', ''
          if (-not $perm.ContainsKey($clean)) {
            "  [$($file.Name):$($i + 1)] 站内链接目标不存在（注意文件名前缀，如 01_）：$target"; $problems++
          }
        }
      }

      if ($seg -match '\\[\(\[]') {
        "  [$($file.Name):$($i + 1)] 用了 \\( \\) 或 \\[ \\]（网站上不渲染）：$($seg.Trim())"; $problems++
      }
      if ($seg -match '\S\$\$[^$]+\$\$' -or $seg -match '\$\$[^$]+\$\$\S') {
        "  [$($file.Name):$($i + 1)] 行内写了 \$\$x\$\$（编辑器预览不认）：$($seg.Trim())"; $problems++
      }

      if ($seg -match '\$') {
        $parts = $seg -split '\$'
        if ($parts.Count % 2 -eq 0) {
          "  [$($file.Name):$($i + 1)] 这一行 \$ 数量是奇数，定界符配对错乱：$($seg.Trim())"; $problems++
        }
        for ($k = 1; $k -lt $parts.Count; $k += 2) {
          $m = $parts[$k]
          $checked++
          if ($m -match '\|') { "  [$($file.Name):$($i + 1)] 公式里有竖线：`$$m`$"; $problems++ }
          if ($m -match '\*') { "  [$($file.Name):$($i + 1)] 公式里有星号（会被当斜体）：`$$m`$"; $problems++ }
          if ($m -match "'") { "  [$($file.Name):$($i + 1)] 公式里有撇号（会被智能引号改）：`$$m`$"; $problems++ }
          if ($m -match '"') { "  [$($file.Name):$($i + 1)] 公式里有双引号（会被智能引号改）：`$$m`$"; $problems++ }
          if ($m -match '\\[{}]') { "  [$($file.Name):$($i + 1)] 公式里有 \{ \} （会被 kramdown 吃掉）：`$$m`$"; $problems++ }
        }
      }
    }

    if ($scan -match '\\(lbrace|rbrace|lvert|rvert|ast|prime)[A-Za-z]') {
      "  [$($file.Name):$($i + 1)] 控制字粘连（KaTeX 会报错）：$($scan.Trim())"; $problems++
    }
  }
}

"`n检查完成：扫描 " + $files.Count + " 个文件、" + $checked + " 条行内公式，发现 $problems 处问题。"
if ($problems -gt 0) { exit 1 }
