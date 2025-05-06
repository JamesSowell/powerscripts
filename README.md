# in your $PROFILE add the following to
```powershell
# import aliases and functions
$profileModulesPath = "$HOME\.config\powerscipts"

Get-ChildItem -Path $profileModulesPath -Filter *.ps1 | ForEach-Object {
    try {
        . $_.FullName
    } catch {
        Write-Warning "Failed to load $($_.Name): $_"
    }
}
```
