param(
  [Parameter(Mandatory=$true)]
  [string]$Line
)

$pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "TDL_Stream", [System.IO.Pipes.PipeDirection]::Out)

try {
  $pipe.Connect(1000)
  $sw = New-Object System.IO.StreamWriter($pipe)
  $sw.AutoFlush = $true
  $sw.WriteLine($Line)
  $sw.Dispose()
}
finally {
  $pipe.Dispose()
}
