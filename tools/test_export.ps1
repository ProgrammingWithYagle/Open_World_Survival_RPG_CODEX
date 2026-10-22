param([ValidateSet('en','zh_CN','zh_TW','es','ja')][string]$Locale='en',[ValidateSet('title','hud','new','inventory','crafting','building','atlas','journal','perks','settings','changelog','dialogue')][string]$Screen='hud')
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskInstall=[IO.Path]::GetFullPath((Join-Path $taskRoot 'exports/smoke_install'))
if (-not $taskInstall.StartsWith($taskRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected install test path' }
New-Item -ItemType Directory -Path $taskInstall -Force | Out-Null
foreach ($taskName in @('The Mossbound Atlas.exe','The Mossbound Atlas.pck')) { Copy-Item -LiteralPath (Join-Path $taskRoot ('exports/windows/'+$taskName)) -Destination (Join-Path $taskInstall $taskName) -Force }
$taskCapture=Join-Path $taskRoot ('verification/export_'+$Screen+'_'+$Locale+'.png')
if (Test-Path -LiteralPath $taskCapture) { Remove-Item -LiteralPath $taskCapture -Force }
$taskStdout=Join-Path $taskRoot ('verification/export_'+$Screen+'_'+$Locale+'.stdout.log')
$taskStderr=Join-Path $taskRoot ('verification/export_'+$Screen+'_'+$Locale+'.stderr.log')
$taskArguments=@('--resolution','1280x720','--',('--capture="'+$taskCapture+'"'),('--screen='+$Screen),('--locale='+$Locale),'--exit=1')
$taskProcess=Start-Process -FilePath (Join-Path $taskInstall 'The Mossbound Atlas.exe') -WorkingDirectory $taskInstall -ArgumentList $taskArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr
if (-not $taskProcess.WaitForExit(30000)) { Stop-Process -Id $taskProcess.Id; throw 'Export smoke test exceeded 30 seconds' }
$taskErrors=Get-Content -LiteralPath $taskStderr -Raw
if ($taskProcess.ExitCode -ne 0 -or $taskErrors -match 'ERROR|instances leaked|RID allocations' -or -not (Test-Path -LiteralPath $taskCapture)) { throw "Export did not render cleanly: $taskErrors" }
Write-Output $taskCapture
