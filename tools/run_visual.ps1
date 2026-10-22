param(
    [ValidateSet('animation','ui')][string]$Suite='ui',
    [string]$Godot='godot',
    [switch]$VerboseEngine
)
$ErrorActionPreference='Stop'
if ($env:GODOT -and $Godot -eq 'godot') { $Godot=$env:GODOT }
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskScene=if ($Suite -eq 'animation') {'res://tests/AnimationSuite.tscn'} else {'res://tests/VisualSuite.tscn'}
$taskOutput=if ($Suite -eq 'animation') {Join-Path $taskRoot 'verification/frames'} else {Join-Path $taskRoot 'verification/ui_matrix'}
$taskArgument=if ($Suite -eq 'animation') {'--animation_out='} else {'--visual_out='}
$taskStdout=Join-Path $taskRoot ('verification/'+$Suite+'-suite.stdout.log')
$taskStderr=Join-Path $taskRoot ('verification/'+$Suite+'-suite.stderr.log')
$taskArgs=@('--path',('"'+(Join-Path $taskRoot 'godot')+'"'),'--resolution','1280x720',$taskScene,'--',($taskArgument+'"'+$taskOutput+'"'))
if ($VerboseEngine) { $taskArgs=@('--verbose')+$taskArgs }
$taskProcess=Start-Process -FilePath $Godot -ArgumentList $taskArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr
$taskStarted=[DateTime]::UtcNow
while (-not $taskProcess.WaitForExit(1000)) {
    $taskErrors=Get-Content -LiteralPath $taskStderr -Raw
    if ($taskErrors -match 'SCRIPT ERROR|SHADER ERROR|Parse Error') { Stop-Process -Id $taskProcess.Id; throw $taskErrors }
    if (([DateTime]::UtcNow-$taskStarted).TotalSeconds -gt 180) { Stop-Process -Id $taskProcess.Id; throw 'Visual suite exceeded three minutes.' }
}
$taskErrors=Get-Content -LiteralPath $taskStderr -Raw
if ($taskErrors -match 'ERROR|instances leaked|RID allocations') { throw $taskErrors }
if ($Suite -eq 'ui') {
    $taskReport=Get-Content -LiteralPath (Join-Path $taskOutput 'report.json') -Raw | ConvertFrom-Json
    if ($taskReport.captures -ne 130 -or $taskReport.issues.Count -ne 0) { throw 'The UI matrix is incomplete or has layout issues.' }
}
Get-Content -LiteralPath $taskStdout -Tail 10
