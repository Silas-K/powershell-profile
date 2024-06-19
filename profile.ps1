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

# tab completion for git
Import-Module posh-git

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

# Vim mode for powershell
Set-PSReadLineOption -EditMode Vi

function OnViModeChange {
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewLine "`e[1 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[5 q"
    }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange


# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
# Customize FZF options (optional)
$env:FZF_DEFAULT_OPTS = '--height 100% '


function PsConfigHome
{
    Set-Location $($env:psconfighome)
}


# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}


function ENV {
    Get-ChildItem ENV:
}

$env:FZF_DEFAULT_OPTS=@"
--layout=reverse
--cycle
--scroll-off=5
--border
--preview-window=right,60%,border-left
--bind ctrl-u:preview-half-page-up
--bind ctrl-d:preview-half-page-down
--bind ctrl-f:preview-page-down
--bind ctrl-b:preview-page-up
--bind ctrl-g:preview-top
--bind ctrl-h:preview-bottom
--bind alt-w:toggle-preview-wrap
--bind ctrl-e:toggle-preview
"@

function _open_path
{
  param (
    [string]$input_path
  )
  if (-not $input_path)
  {
    return
  }
  Write-Output "[ ] cd"
  Write-Output "[*] nvim"
  $choice = Read-Host "Enter your choice"
  if ($input_path -match "^.*:\d+:.*$")
  {
    $input_path = ($input_path -split ":")[0]
  }
  switch ($choice)
  {
    {$_ -eq "" -or $_ -eq " "}
    {
      if (Test-Path -Path $input_path -PathType Leaf)
      {
        $input_path = Split-Path -Path $input_path -Parent
      }
      Set-Location -Path $input_path
    }
    default
    { nvim $input_path
    }
  }
}

function _get_path_using_fd
{
  $input_path = fd --type file --follow --hidden --exclude .git |
    fzf --prompt 'Files> ' `
      --header-first `
      --header 'CTRL-S: Switch between Files/Directories' `
      --bind 'ctrl-s:transform:if not "%FZF_PROMPT%"=="Files> " (echo ^change-prompt^(Files^> ^)^+^reload^(fd --type file^)) else (echo ^change-prompt^(Directory^> ^)^+^reload^(fd --type directory^))' `
      --preview 'if "%FZF_PROMPT%"=="Files> " (bat --color=always {} --style=plain) else (eza -T --colour=always --icons=always {})'
  return $input_path
}

function _get_path_using_rg
{
  $INITIAL_QUERY = "${*:-}"
  $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"
  $input_path = "" |
    fzf --ansi --disabled --query "$INITIAL_QUERY" `
      --bind "start:reload:$RG_PREFIX {q}" `
      --bind "change:reload:sleep 0.1 & $RG_PREFIX {q} || rem" `
      --bind 'ctrl-s:transform:if not "%FZF_PROMPT%" == "1. ripgrep> " (echo ^rebind^(change^)^+^change-prompt^(1. ripgrep^> ^)^+^disable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-f ^& cat %TEMP%\rg-fzf-r) else (echo ^unbind^(change^)^+^change-prompt^(2. fzf^> ^)^+^enable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-r ^& cat %TEMP%\rg-fzf-f)' `
      --color "hl:-1:underline,hl+:-1:underline:reverse" `
      --delimiter ":" `
      --prompt '1. ripgrep> ' `
      --preview-label "Preview" `
      --header 'CTRL-S: Switch between ripgrep/fzf' `
      --header-first `
      --preview 'bat --color=always {1} --highlight-line {2} --style=plain' `
      --preview-window 'up,60%,border-bottom,+{2}+3/3'
  return $input_path
}

function fdg
{
  _open_path $(_get_path_using_fd)
}

function rgg
{
  _open_path $(_get_path_using_rg)
}


# SET KEYBOARD SHORTCUTS TO CALL FUNCTION

Set-PSReadLineKeyHandler -Key "Ctrl+f" -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("fdg")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key "Ctrl+g" -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("rgg")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
