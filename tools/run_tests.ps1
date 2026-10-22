param([ValidateSet('runtime','integration')][string]$Suite='runtime',[string]$Godot='godot')
$ErrorActionPreference='Stop'
if ($env:GODOT -and $Godot -eq 'godot') { $Godot=$env:GODOT }
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskStdout=Join-Path $taskRoot ('verification/'+$Suite+'-tests.stdout.log')
$taskStderr=Join-Path $taskRoot ('verification/'+$Suite+'-tests.stderr.log')
$taskScene=if ($Suite -eq 'integration') {'res://tests/IntegrationSuite.tscn'} else {'res://tests/TestSuite.tscn'}
$taskArguments=@('--headless','--path',('"'+(Join-Path $taskRoot 'godot')+'"'),$taskScene,'--quit-after','1200')
$taskProcess=Start-Process -FilePath $Godot -ArgumentList $taskArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr
if (-not $taskProcess.WaitForExit(45000)) { Stop-Process -Id $taskProcess.Id; throw 'Runtime tests exceeded 45 seconds.' }
$taskOutput=Get-Content -LiteralPath $taskStdout -Raw
$taskErrors=Get-Content -LiteralPath $taskStderr -Raw
Write-Output $taskOutput
if ($taskErrors -match 'ERROR|FAIL:' -or $taskOutput -notmatch '(RUNTIME|INTEGRATION)_TESTS \d+ checks; 0 failures') { throw $taskErrors }
