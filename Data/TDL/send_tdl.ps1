param(
  [Parameter(Mandatory=$true)][string]$Action,
  [int]$Source = 2
)

$pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "TDL_Stream", [System.IO.Pipes.PipeDirection]::Out)
$pipe.Connect(1000)
$sw = New-Object System.IO.StreamWriter($pipe)
$sw.AutoFlush = $true
$sw.WriteLine("$Action|$Source")
$sw.Dispose()
$pipe.Dispose()
