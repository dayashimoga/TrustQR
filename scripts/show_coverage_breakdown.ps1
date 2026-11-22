$lcovPath = "h:\qrscanner\packages\qr_core\coverage\lcov.info"
$currentFile = ""
$missed = @{}
$total = @{}
$hit = @{}

foreach ($line in Get-Content $lcovPath) {
    if ($line -match '^SF:(.*)') {
        $currentFile = $matches[1]
        if (-not $missed.ContainsKey($currentFile)) {
            $missed[$currentFile] = 0
            $total[$currentFile] = 0
            $hit[$currentFile] = 0
        }
    } elseif ($line -match '^DA:(\d+),(\d+)') {
        $total[$currentFile]++
        $count = [int]$matches[2]
        if ($count -eq 0) {
            $missed[$currentFile]++
        } else {
            $hit[$currentFile]++
        }
    }
}

$results = foreach ($k in $total.Keys) {
    $pct = [math]::Round(($hit[$k] / $total[$k]) * 100, 1)
    [PSCustomObject]@{
        File = (Split-Path $k -Leaf)
        Hit = $hit[$k]
        Total = $total[$k]
        Missed = $missed[$k]
        Coverage = "$pct%"
    }
}
$results | Format-Table -AutoSize
