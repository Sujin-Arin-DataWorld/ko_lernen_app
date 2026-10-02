param(
 [string]$BaseUrl='http://127.0.0.1:8814',
 [string]$BrowserSession='hs-content-grid-package-01a0fe06'
)
$ErrorActionPreference='Stop'
$results=@()
function Browser([string[]]$arguments) {
 $raw=& agent-browser --session $browserSession --json @arguments
 if($LASTEXITCODE -ne 0){throw ($raw -join "`n")}
 $value=($raw -join "`n") | ConvertFrom-Json
 if(-not $value.success){throw $value.error}
 return $value.data
}
foreach($case in @(
 @{width=320;locale='de';demo='';extra=''},
 @{width=390;locale='de';demo='';extra=''},
 @{width=390;locale='en';demo='';extra=''},
 @{width=390;locale='ko';demo='';extra=''},
 @{width=480;locale='de';demo='';extra=''},
 @{width=320;locale='de';demo='discover';extra='&text=large&motion=reduce'},
 @{width=390;locale='de';demo='frequent';extra=''},
 @{width=390;locale='de';demo='discover';extra=''}
)) {
 Browser @('set','viewport',"$($case.width)",'844') | Out-Null
 $url="$BaseUrl/?view=today&lang=$($case.locale)&clean=1$($case.extra)"
 if($case.demo){$url+='&demo='+$case.demo}
 Browser @('open',$url) | Out-Null
 Browser @('wait','--fn',"document.documentElement.dataset.screenReady === 'true' && [...document.querySelectorAll('.content-tile img')].every(i => i.complete && i.naturalWidth > 0)") | Out-Null
 $qaExpression=Get-Content -Raw -LiteralPath qa/layout-check.js
 $check=(Browser @('eval',$qaExpression)).result
 if($check.count -ne 4 -or $check.subtitles -ne 0 -or -not $check.images -or $check.minTap -lt 48 -or -not $check.labelInside -or $check.overflow -or $check.nav -ne 5 -or -not $check.font){throw ('Layout failed: '+($check|ConvertTo-Json -Compress))}
 if($check.inventory.learn -ne 13 -or $check.inventory.games -ne 8 -or $check.inventory.packs -ne 252){throw 'Catalog omitted'}
 if($case.demo -eq 'discover' -and $check.discovery -ne 'hangul'){throw 'Discovery fixture failed'}
 if($case.extra -and $check.transform -ne 'none'){throw 'Reduced motion transform'}
 $results+=$check
}
$results|ConvertTo-Json -Depth 8 | Set-Content -LiteralPath qa/layout-results.json -Encoding utf8
Write-Output "PASS: $($results.Count) layout cases (320-480px, DE/EN/KO, enlarged text, reduced motion, personalised and discovery states)."
