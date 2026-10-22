param(
    [ValidateSet('en','zh_CN','zh_TW','es','ja')][string]$Locale='en',
    [ValidateSet('title','hud','new','inventory','crafting','building','atlas','journal','perks','settings','changelog','dialogue')][string]$Screen='title',
    [string]$Godot='godot'
)
$ErrorActionPreference='Stop'
if ($env:GODOT -and $Godot -eq 'godot') { $Godot=$env:GODOT }
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskProject=Join-Path $taskRoot 'godot'
$taskOutput=Join-Path $taskRoot 'verification'
$taskCapture=Join-Path $taskOutput ($Screen+'_'+$Locale+'.png')
if (Test-Path -LiteralPath $taskCapture) { Remove-Item -LiteralPath $taskCapture -Force }
$taskStdout=Join-Path $taskOutput ($Screen+'_'+$Locale+'.stdout.log')
$taskStderr=Join-Path $taskOutput ($Screen+'_'+$Locale+'.stderr.log')
$taskArguments=@('--path',('"'+$taskProject+'"'),'--resolution','1280x720','--',('--capture="'+$taskCapture+'"'),('--screen='+$Screen),('--locale='+$Locale),'--exit=1')
$taskProcess=Start-Process -FilePath $Godot -ArgumentList $taskArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr
if (-not $taskProcess.WaitForExit(25000)) {
    Stop-Process -Id $taskProcess.Id
    throw 'Game capture did not finish within 25 seconds.'
}
$taskErrors=Get-Content -LiteralPath $taskStderr -Raw
if ($taskErrors -match 'SCRIPT ERROR|SHADER ERROR|Parse Error') { throw $taskErrors }
if (-not (Test-Path -LiteralPath $taskCapture)) { throw "No game image was captured. $taskErrors" }
Write-Output $taskCapture
