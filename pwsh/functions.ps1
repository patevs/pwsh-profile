# functions.ps1
# -------------

# Write-Output "functions.ps1"

# ---------------- #
# Helper Functions | ------------------------------------------------------------------------------------ #
# ---------------- #

# Current Foreground and Background Colors
#   https://stackoverflow.com/a/26583010
# $foreground = (get-host).ui.rawui.ForegroundColor
# $background = (get-host).ui.rawui.BackgroundColor
# Set-Variable background -option Constant -value (get-host).ui.rawui.BackgroundColor

function Write-BoldGreen($str) {
  # TODO: Ensure PSWrite-Color is installed
  # Current console background color
  $BG = (get-host).ui.rawui.BackgroundColor
  Write-Color "`n" -B $BG -NoNewLine
  Write-Color " $str " -B Green -C $BG
  Write-Color "`n" -B $BG -NoNewLine
}

# -------------- #
# Basic Commands | -------------------------------------------------------------------------------------- #
# -------------- #

function which($name) { Get-Command $name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }
function grep($regex, $dir) {
  if ( $dir ) {
    get-childitem $dir | select-string $regex
    return
  }
  $input | select-string $regex
}

# Common Editing needs
# function Edit-Hosts { Invoke-Expression "sudo $(if($env:EDITOR -ne $null)  {$env:EDITOR } else { 'notepad' }) $env:windir\system32\drivers\etc\hosts" }
# function Edit-Profile { Invoke-Expression "$(if($env:EDITOR -ne $null)  {$env:EDITOR } else { 'notepad' }) $profile" }

# Kinda like $EDITOR in nix
# TODO: check out edit-file from PSCX
# You may prefer eg 'subl' or 'code' or whatever else
function edit {
	& "code" -g @args
}

# Edit whole dir, so we can edit included files etc.
function edit-profile {
  edit $PSScriptRoot
}

# Open a given file
function open($file) {
  # Use open-cli if installed
  if (which open-cli) {
    open-cli $file
  } else {
    invoke-item $file
  }
}

# Open Windows Explorer
function explorer {
  explorer.exe .
}

# Open Windows Settings
function settings {
  start-process ms-setttings:
}

# Truncate homedir to ~
# function limit-HomeDirectory($Path) {
#   $Path.Replace("$home", "~")
# }

# TODO: Create function to start FireFox
# function edge {
  # Old Edge
  # start microsoft-edge:
  #
  # New Chromioum Edge
#   & "${env:ProgramFiles(x86)}\Microsoft\Edge Dev\Application\msedge.exe"
# }

# ---------------------------- #
# PowerShell Utility Functions | ------------------------------------------------------------------------ #
# ---------------------------- #

# Reload the Shell
function Invoke-Powershell {
  $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
  $newProcess.Arguments = "-nologo";
  [System.Diagnostics.Process]::Start($newProcess);
  # exit
}
# function ReloadPowershell { & $profile }

# Set the current console title
# https://blogs.technet.microsoft.com/heyscriptingguy/2012/12/30/powertip-change-the-powershell-console-title
function Set-ConsoleTitle([string]$newtitle) {
  $host.ui.RawUI.WindowTitle = $newtitle + ' – ' + $host.ui.RawUI.WindowTitle
}

# Reset the console colors
# https://stackoverflow.com/a/42624497
function Reset-Console-Colors {
  [Console]::ResetColor()
}

function Reset-Console {
  # Reset console colors
  Reset-Console-Colors
  # Clear the console
  Clear-Host
}

# ------------------------ #
# System Utility Functions | ---------------------------------------------------------------------------- #
# ------------------------ #

# System Update - Update RubyGems, NPM, and their installed packages
<#
function SystemUpdate() {
  # Install-WindowsUpdate -IgnoreUserInput -IgnoreReboot -AcceptAll
  Update-Module
  # Update-Help -Force
  gem update --system
  gem update
  npm install npm -g
  npm update -g
}
#>

# https://stackoverflow.com/a/7330368
function Get-WindowsBuild {
  Write-Green "WINDOWS ENVIRONMENT"
  [Environment]::OSVersion
  [System.Environment]::OSVersion.Version
}

function Get-Version {
  $PSVersionTable.PSVersion; Get-WindowsBuild
}

# function get-serial-number {
#   Get-CimInstance -ClassName Win32_Bios | select-object serialnumber
# }

# function disable-windows-search {
# 	Set-Service wsearch -StartupType disabled
# 	stop-service wsearch
# }

# --------------------- #
# File System Functions | ------------------------------------------------------------------------------- #
# --------------------- #

# Create a new directory and enter it
function CreateAndSetDirectory([String] $path) {
  New-Item $path -ItemType Directory -ErrorAction SilentlyContinue
  Set-Location $path
}

# Delete a given item
function RemoveItem([string]$path) {
  Remove-Item -Path $path -Recurse -Force
}

# Empty the Recycle Bin on all drives
function EmptyRecycleBin {
  $RecBin = (New-Object -ComObject Shell.Application).Namespace(0xA)
  # $RecBin.Items() | %{Remove-Item $_.Path -Recurse -Confirm:$false}
  $RecBin.Items() | ForEach-Object{Remove-Item $_.Path -Recurse -Confirm:$false}
}

# Cleanup all disks (Based on Registry Settings in `windows.ps1`)
function CleanDisks {
  Start-Process "$(Join-Path $env:WinDir 'system32\cleanmgr.exe')" -ArgumentList "/sagerun:6174" -Verb "runAs"
}

# --------------------- #
# Environment Functions | ------------------------------------------------------------------------------- #
# --------------------- #

# Reload the $env object from the registry
function RefreshEnvironment {
  $locations =
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'HKCU:\Environment'

  $locations | ForEach-Object {
    $k = Get-Item $_
    $k.GetValueNames() | ForEach-Object {
      $name  = $_
      $value = $k.GetValue($_)
      Set-Item -Path Env:\$name -Value $value
    }
  }

  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Set a permanent Environment variable, and reload it into $env
function Set-Environment([String] $variable, [String] $value) {
  Set-ItemProperty "HKCU:\Environment" $variable $value
  # Manually setting Registry entry. SetEnvironmentVariable is too slow because of blocking HWND_BROADCAST
  #[System.Environment]::SetEnvironmentVariable("$variable", "$value","User")
  Invoke-Expression "`$env:${variable} = `"$value`""
}

# Get Environment Path
function Get-Path {
	($Env:Path).Split(";")
}

# Add a folder to $env:Path
function PrependEnvPath([String]$path) { $env:PATH = $env:PATH + ";$path" }
function AppendEnvPath([String]$path) { $env:PATH = $env:PATH + ";$path" }

# function PrependEnvPathIfExists([String]$path) { if (Test-Path $path) { PrependEnvPath $path } }
# function AppendEnvPathIfExists([String]$path) { if (Test-Path $path) { AppendEnvPath $path } }

# ------------- #
# Git Functions | --------------------------------------------------------------------------------------- #
# ------------- #

# Print Git Status
function Get-GitStatus {
  # Write-Host "`n Git Status `n" -Color Green
  Write-BoldGreen "Git Status"
  git status
}

# Print git status using g3l
function gss {
  # Fetch git remote
  Write-BoldGreen "Git Remotes"
  git remote -v
  Get-GitStatus
  # Git branch status
  # Write-BoldGreen "Local Branches"
  if (which g3l) { g3l --status }
  # Write-BoldGreen "Remote Branches"
  # gbs --remotes
}

# Clone a git repository and cd into the created directory
# https://stackoverflow.com/a/32539370/6346131
function Invoke-GitClone($url) {
  $name = $url.Split('/')[-1].Replace('.git', '')
  # ! Check if `hub` is installed.
  # ! Will hang if not authenticated
  & git clone $url $name | Out-Null
  Set-Location $name
}

# ---------------------- #
# NodeJS & NPM Functions | ------------------------------------------------------------------------------ #
# ---------------------- #

# Print list of local NPM dependencies
function npl {
  # Print-Green-Underline "Local NPM Dependencies:"
  # Write-Output "`n Local NPM Dependencies: `n"
  Write-BoldGreen "Local NPM Packages"
  npm list --depth=0
}

# Print list of global NPM dependencies
function nplg {
  # Print-Green-Underline "Global NPM Dependencies:"
  # Write-Output "`n Global NPM Dependencies: `n"
  Write-BoldGreen "Global NPM Packages"
  npm list --global --depth=0
}

# -------------------- #
# Chocolatey Functions | -------------------------------------------------------------------------------- #
# -------------------- #

# Print list of local chocolatey installations
function cll {
  # Print-Green-Underline "Local Chocolatey Installations:"
  # Write-Output "`n Local Chocolatey Installations:`n"
  Write-BoldGreen "Local Chocolatey Installations"
  choco list -l
}

# Print list of outdated chocolatey installations
function clo {
  # Print-Green-Underline "Outdated Chocolatey Installations:"
  # Write-Output "`n Outdated Chocolatey Installations:`n"
  Write-BoldGreen "Outdated Chocolatey Installations"
  choco upgrade all --noop
}

# --------------- #
# Scoop Functions | -------------------------------------------------------------------------------- #
# --------------- #

# Print list of local scoop installations
function sll {
  # Write-Output "`n Local Scoop Installations:`n"
  Write-BoldGreen "Local Scoop Installations"
  scoop list
}

# ----------------------------------------------- # EOF # ----------------------------------------------- #
