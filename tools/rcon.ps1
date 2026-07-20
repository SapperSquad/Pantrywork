param(
  [string]$File,
  [string]$Command,
  [int]$Port = 25575,
  [string]$Password = "pantrywork"
)
# Minimal RCON client, adapted from ReelRivals/tools/rcon_cmd.ps1.
$ErrorActionPreference = "Stop"
function Read-Exact($stream, $count) {
  $buf = New-Object byte[] $count; $off = 0
  while ($off -lt $count) { $n = $stream.Read($buf, $off, $count - $off); if ($n -le 0) { throw "socket closed" }; $off += $n }
  return $buf
}
function Send-Pkt($stream, $id, $type, $body) {
  $b = [Text.Encoding]::UTF8.GetBytes($body)
  $ms = New-Object IO.MemoryStream; $w = New-Object IO.BinaryWriter($ms)
  $w.Write([int](4 + 4 + $b.Length + 2)); $w.Write([int]$id); $w.Write([int]$type); $w.Write($b); $w.Write([byte]0); $w.Write([byte]0)
  $bytes = $ms.ToArray(); $stream.Write($bytes, 0, $bytes.Length); $stream.Flush()
}
function Read-Pkt($stream) {
  $len = [BitConverter]::ToInt32((Read-Exact $stream 4), 0)
  $rest = Read-Exact $stream $len
  return @{ id = [BitConverter]::ToInt32($rest, 0); body = [Text.Encoding]::UTF8.GetString($rest, 8, $len - 10) }
}
$client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", $Port)
$s = $client.GetStream(); $s.ReadTimeout = 30000
Send-Pkt $s 1 3 $Password; if ((Read-Pkt $s).id -eq -1) { throw "RCON auth failed" }
$cmds = if ($Command) { @($Command) } else { Get-Content $File | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") } }
foreach ($cmd in $cmds) {
  Send-Pkt $s 7 2 $cmd
  Start-Sleep -Milliseconds 150
  $resp = (Read-Pkt $s).body
  ">> $cmd"
  "   $resp"
}
$client.Close()
