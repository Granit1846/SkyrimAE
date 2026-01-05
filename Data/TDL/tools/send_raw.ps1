param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("NORMAL","FORCE1","FORCE")]
  [string]$Mode,

  [Parameter(Mandatory=$true)]
  [string]$Action,

  [int]$Source = 2,

  [int]$Count = 1,

  [double]$Interval = -1
)

switch ($Mode) {
  "NORMAL" {
    $line = "$Action|$Source"
  }
  "FORCE1" {
    $line = "FORCE1|$Action"
  }
  "FORCE" {
    if ($Interval -gt 0) {
      $line = "FORCE|$Action|$Count|$Interval"
    } else {
      $line = "FORCE|$Action|$Count"
    }
  }
}

$pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "TDL_Stream", [System.IO.Pipes.PipeDirection]::Out)

try {
  $pipe.Connect(1000)
  $sw = New-Object System.IO.StreamWriter($pipe)
  $sw.AutoFlush = $true
  $sw.WriteLine($line)
  $sw.Dispose()
}
finally {
  $pipe.Dispose()
}
