$ErrorActionPreference = 'Stop'

function New-StringFromCodePoints([int[]]$codes) {
  return -join ($codes | ForEach-Object { [char]$_ })
}

$roots = @('lib', 'docs')
$badSequences = @(
  (New-StringFromCodePoints @(0x00C4, 0x201A)),
  (New-StringFromCodePoints @(0x0102, 0x201E)),
  (New-StringFromCodePoints @(0x0102, 0x201A)),
  (New-StringFromCodePoints @(0x00C2, 0x00A1)),
  (New-StringFromCodePoints @(0x00C2, 0x00BA)),
  (New-StringFromCodePoints @(0x00C2, 0x00BB)),
  (New-StringFromCodePoints @(0x00E2, 0x20AC)),
  (New-StringFromCodePoints @(0x00EF, 0x00BF, 0x00BD)),
  [string]([char]0xFFFD),
  (New-StringFromCodePoints @(0x00E1, 0x00BA)),
  (New-StringFromCodePoints @(0x00E1, 0x00BB)),
  (New-StringFromCodePoints @(0x00C3, 0x00A1)),
  (New-StringFromCodePoints @(0x00C3, 0x00A0))
)

$pattern = ($badSequences | ForEach-Object { [regex]::Escape([string]$_) }) -join '|'
$files = foreach ($root in $roots) {
  if (Test-Path -LiteralPath $root) {
    Get-ChildItem -LiteralPath $root -Recurse -File |
      Where-Object { $_.Extension -in '.dart', '.md', '.yaml', '.yml', '.json' }
  }
}

$matches = foreach ($file in $files) {
  Select-String -LiteralPath $file.FullName -Pattern $pattern -Encoding UTF8
}

if ($matches) {
  Write-Host 'Possible mojibake/encoding issues found:' -ForegroundColor Red
  $matches | ForEach-Object {
    $relative = Resolve-Path -LiteralPath $_.Path -Relative
    Write-Host ('{0}:{1}: {2}' -f $relative, $_.LineNumber, $_.Line.Trim())
  }
  exit 1
}

Write-Host 'No mojibake markers found.' -ForegroundColor Green
