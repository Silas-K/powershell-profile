
# Linked Files (Destination => Source)
$symlinks = @{
    $PROFILE.CurrentUserAllHosts                                                                    = ".\Profile.ps1"
    "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" = ".\windowsterminal\settings.json"
}
# Create Symbolic Links
Write-Host "Creating Symbolic Links..."
foreach ($symlink in $symlinks.GetEnumerator())
{
    Get-Item -Path $symlink.Key -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $symlink.Key -Target (Resolve-Path $symlink.Value) -Force | Out-Null
}

# Persist Environment Variables (directory for nvim)
[System.Environment]::SetEnvironmentVariable('nvimhome', "$($env:LocalAppData)\nvim", [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('psconfighome', "$($PSScriptRoot)", [System.EnvironmentVariableTarget]::User)
