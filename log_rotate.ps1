$LogFile          = 'C:\project\log_rotate\log.log'
$PathLogArchive   = 'C:\project\log_rotate\Logs\'
$RententionInDays = 100
$DateTimeFormat   = "dd-MM-yyyy HH'h'mm"
$Format           = '{0}_[{1}]{2}'
$ServiceName      = 'Stunnel'


function Archive($Dest, $Source)
{
    Add-Type -Assembly System.IO.Compression.FileSystem
    $cLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Source, $Dest, $cLevel, $false)
}

If (Test-Path -LiteralPath $LogFile)
{
    $S = Get-Item -LiteralPath $LogFile
    $Filename = $S.BaseName + "_[" + ((Get-Date).ToString($DateTimeFormat)) + "]"
    $Dest = Join-Path -Path $PathLogArchive -ChildPath $Filename
    $Dest = $Dest + '.zip'
    $Temp = Join-Path -Path $PathLogArchive -ChildPath "temp"
    If (!(Test-Path -LiteralPath $Temp)) {$Null = New-Item -Path $Temp -Type Directory -Force}
    $Tempfile = $Temp + '\' + $Filename + $S.Extension
    Copy-Item -Path $LogFile -Destination $Tempfile -Force
    Stop-Service -Name $ServiceName -Force
    (Get-Service $ServiceName).WaitForStatus('Stopped')
    Start-Sleep -s 1
    Clear-Content -LiteralPath $LogFile -Force 
    Start-Service -Name $ServiceName
    Archive -Dest $Dest -Source $Temp
    Remove-Item -ErrorAction SilentlyContinue -Path $Temp -Recurse
    Get-ChildItem -LiteralPath $PathLogArchive -File -Filter ($Format -F $S.BaseName, '*',".zip") | ? LastWriteTime -le ((Get-Date).AddDays(-$RententionInDays)) | Remove-Item -ErrorAction SilentlyContinue
}
