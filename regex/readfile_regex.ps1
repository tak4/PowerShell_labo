$lines = Get-Content "sample.txt"
foreach ($line in $lines) {
    if($line -match "(.+was )(.+)"){
        $Matches
        # $Matches[1]
    }
}