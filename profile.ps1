# set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Function Get-RealScriptPath()
{
    # Get script path and name
    $ScriptPath = $PSCommandPath

    # Attempt to extract link target from script pathname
    $link_target = Get-Item $ScriptPath | Select-Object -ExpandProperty Target

    # If it's not a link ..
    If(-Not($link_target))
    {
        # .. then the script path is the answer.
        return $ScriptPath
    }

    # If the link target is absolute ..
    $is_absolute = [System.IO.Path]::IsPathRooted($link_target)
    if($is_absolute)
    {
        # .. then it is the answer.
        return $link_target
    }

    # At this point:
    # - we know that script was launched from a link
    # - the link target is probably relative (depending on how accurate
    #   IsPathRooted() is).
    # Try to make an absolute path by merging the script directory and the link
    # target and then normalize it through Resolve-Path.
    $joined = Join-Path $PSScriptRoot $link_target
    $resolved = Resolve-Path -Path $joined
    return $resolved
}

Function Get-ScriptDirectory()
{
    $ScriptPath = Get-RealScriptPath
    $ScriptDir = Split-Path -Parent $ScriptPath
    return $ScriptDir
}

# Environment Variables
# bat tool: https://github.com/sharkdp/bat
# theme-configuration: https://github.com/folke/tokyonight.nvim/issues/23
$env:BAT_THEME="tokyonight_night"
$env:nvimhome="$($env:LocalAppData)\nvim"
$env:psconfighome="$(Get-ScriptDirectory)"

# Aliases
Set-Alias vi nvim
Set-Alias vim nvim
Set-Alias ll ls
Set-Alias grep findstr

# Custom modules/plugins configuration
# oh-my-posh init pwsh --config "$env:psconfighome\capr4n_power10k_ssh.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:psconfighome\capr4n_power10k_modified_2lines.omp.json" | Invoke-Expression
$omp_config = Join-Path $env:psconfighome ".\capr4n_power10k_modified_2lines.omp.json"
oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression
Import-Module git-aliases -DisableNameChecking

# icons for files 
Import-Module -Name Terminal-Icons

# Fzf
Import-Module PSFzf
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'


#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
If (Test-Path "C:\Users\silas\anaconda3\Scripts\conda.exe")
{
(& "C:\Users\silas\anaconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion


function PsConfigHome
{
    Set-Location $($env:psconfighome)
}


# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
