# CountSuite.ps1 - classify an RCON suite's output (tools\rcon.ps1 -File <suite> > <out>).
#
#   powershell -File tools\CountSuite.ps1 -Suite tools\tagtest-neo26-gates.txt -Output run\neo26-gates.out
#
# rcon.ps1 prints ">> <command>" then the server's answer for every non-comment line of the
# suite, in order. This script pairs each answer with its suite line and classifies every
# `execute ...` line:
#   passed    "Test passed"
#   expected  the answer starts with the text of an `# expect: <text>` comment placed on the
#             line(s) directly above the command (e.g. `# expect: Unknown item tag`)
#   failed    anything else: "Test failed", an unannotated "Unknown item tag", a syntax error,
#             "No entity was found", a missing answer
# An annotated line that answers "Test passed" is ALSO a failure (the expectation did not hold:
# for a closed-gate probe that means the gate overlay leaked).
# Exit code 1 when failed > 0, when the output does not match the suite line for line, or when
# nothing was classified at all (0 passed / 0 failed = the suite DID NOT RUN).
param([Parameter(Mandatory)][string]$Suite, [Parameter(Mandatory)][string]$Output, [switch]$Quiet)
$ErrorActionPreference = 'Stop'

$cmds = New-Object System.Collections.ArrayList
$pending = $null
foreach ($raw in [IO.File]::ReadAllLines((Resolve-Path $Suite))) {
  $l = $raw.Trim()
  if ($l -eq '') { continue }
  if ($raw.StartsWith('#')) {
    if ($l -match '^#\s*expect:\s*(.+?)\s*$') { $pending = $matches[1] }
    continue
  }
  [void]$cmds.Add(@{ cmd = $raw; expect = $pending })
  $pending = $null
}

$answers = New-Object System.Collections.ArrayList
$lines = [IO.File]::ReadAllLines((Resolve-Path $Output))
for ($i = 0; $i -lt $lines.Count; $i++) {
  if (-not $lines[$i].StartsWith('>> ')) { continue }
  $resp = @(); $k = $i + 1
  while ($k -lt $lines.Count -and -not $lines[$k].StartsWith('>> ')) { $resp += $lines[$k].Trim(); $k++ }
  [void]$answers.Add(@{ cmd = $lines[$i].Substring(3); resp = (($resp | Where-Object { $_ -ne '' }) -join ' | ') })
}

$passed = 0; $failed = 0; $expected = 0; $report = @()
if ($answers.Count -ne $cmds.Count) { $failed++; $report += "MISMATCH: suite has $($cmds.Count) commands, output has $($answers.Count) answers" }
$n = [Math]::Min($answers.Count, $cmds.Count)
for ($j = 0; $j -lt $n; $j++) {
  $c = $cmds[$j]; $a = $answers[$j]
  if ($a.cmd -ne $c.cmd) { $failed++; $report += "MISMATCH at command $($j + 1): suite '$($c.cmd)' vs output '$($a.cmd)'"; break }
  if ($c.cmd -notlike 'execute *') {
    if ($a.resp -match '^(Unknown|Incorrect argument|Expected|Invalid)') { $report += "  note (non-assert): $($c.cmd) => $($a.resp)" }
    continue
  }
  if ($c.expect) {
    if ($a.resp.StartsWith($c.expect)) { $expected++ }
    else { $failed++; $report += "  FAIL (expected '$($c.expect)'): $($c.cmd) => $($a.resp)" }
  } elseif ($a.resp -like 'Test passed*') { $passed++ }
  else { $failed++; $report += "  FAIL: $($c.cmd) => $($a.resp)" }
}
$didNotRun = ($passed + $failed + $expected) -eq 0
"{0}: passed={1} failed={2} expected={3}{4}" -f [IO.Path]::GetFileName($Suite), $passed, $failed, $expected, $(if ($didNotRun) { '  <-- 0/0: DID NOT RUN (failure)' } else { '' })
if (-not $Quiet) { $report | ForEach-Object { $_ } }
if ($failed -gt 0 -or $didNotRun) { exit 1 }
exit 0
