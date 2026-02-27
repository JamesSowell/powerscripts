
# Alises
Set-Alias vim nvim
Set-Alias en jq
Set-Alias x z
Set-Alias nn ls
Set-Alias cs clear
Set-Alias grep findstr

function restartshell {
    . $PROFILE
}

function la {
    Get-ChildItem -Force
}

# Function to create a directory and immediately change into it
function mkcd {
    param (
        [string]$dirName
    )
    if (-not $dirName) {
        Write-Host "Usage: mkcd <directory_name>"
        return
    }
    New-Item -Path $dirName -ItemType Directory -Force | Out-Null
    Set-Location -Path $dirName
}

# Alias to copy the contents of a file to the clipboard
function ccat {
    param (
        [string]$fileName
    )

    if (Test-Path $fileName) {
        Get-Content $fileName | clip
        Write-Host "$fileName content copied to clipboard."
    }
    else {
        Write-Host "Error: File not found."
    }
}

function nt {
    wt -w 0 nt -d .
}

function whereis ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function editprofile {
    code $PROFILE
}

function gotalonuser {
    Set-Location $HOME\AppData\Roaming\talon\user
}

function gomywintalonuser {
    Set-Location $HOME\AppData\Roaming\talon\user\my-talon
}

# node
function nomodules {
    Get-ChildItem -Path . -Recurse -Directory -Name node_modules | ForEach-Object {
        Remove-Item -Recurse -Force $_
    }
}

function nopackagelock {
    Get-ChildItem . -Recurse -Filter package-lock.json -File |
        Remove-Item -Force
}

Set-Alias g git



function glo {
    git log --oneline -n 15
}


function gs {
    git switch -
}

function gb {
    git branch
}

function gbn {
    git rev-parse --abbrev-ref HEAD
    git rev-parse --abbrev-ref HEAD | Set-Clipboard
}

function gbh {
    git rev-parse --short HEAD
    git rev-parse --short HEAD | Set-Clipboard
}

function gpb {
    git switch -
}


function gnb {
    # get name of the current branch
    $currentBranch = git rev-parse --abbrev-ref HEAD

    # Get the list of all local branches
    $branches = @(git for-each-ref --format '%(refname:short)' refs/heads/)

    # Find the index of the current branch in the list
    $currentIndex = $branches.IndexOf($currentBranch)

    # Find the index of the current branch in the list
    $nextIndex = ($currentIndex + 1) % $branches.Length

    # Switch to the next branch
    git switch $branches[$nextIndex]
}


# stash
function gstashapply {
    param(
        [Parameter(Mandatory=$true)]
        [int]$n
    )

    git stash apply "stash@{$n}"
}

function gstash {
    git stash list
}

# powershell
function checkalias {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Name
    )

    $alias = Get-Alias -Name $Name -ErrorAction SilentlyContinue
    if ($alias) {
        "Alias '$Name' exists -> $($alias.Definition)"
    } else {
        "Alias '$Name' does not exist"
    }
}
function gco {
    param(
        [Parameter(Position=0)]
        [string]$sel,
        [switch]$all   # include remotes
    )

    # checkout by number
    if ($sel -match '^\d+$') {
        $i = [int]$sel
        if (-not $global:lastBranches -or $i -lt 0 -or $i -ge $global:lastBranches.Count) {
            Write-Error "Index out of range. Run: gco"
            return
        }

        $b = ($global:lastBranches[$i] -as [string]).Trim()

        # If it's a remote branch like origin/foo, create tracking branch
        if ($b -match '^[^/]+/.+') {
            $local = ($b -split '/', 2)[1]
            git switch -c $local --track $b
        } else {
            git switch -- $b
        }
        return
    }

    # list branches (clean names)
    $refs = @('refs/heads')
    if ($all) { $refs += 'refs/remotes' }

    $global:lastBranches = @(
        git for-each-ref $refs --format="%(refname:short)" |
            Where-Object { $_ } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and $_ -ne 'HEAD' }
    )

    for ($i = 0; $i -lt $global:lastBranches.Count; $i++) {
        Write-Host "[$i] $($global:lastBranches[$i])"
    }
    Write-Host "`nCheckout with: gco <index>"
    Write-Host "Include remotes with: gco -all"
}



# obsidian
function obs {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VaultName
    )
    
    Start-Process "obsidian://open?vault=$VaultName"
}



# JQ testing code 
# curl.exe -s https://api.github.com/repos/jqlang/jq | jq '{ yessith: .owner.login, noith: .network_count } '


# to practice curl on certain APIS that may require bearer token
# curl.exe -s -X POST https://api.example.com/endpoint `
#   -H "Authorization: Bearer $TOKEN" `
#   -H "Content-Type: application/json" `
#   --data-raw '{"name":"James"}' `
#   -w "\nHTTP Status: %{http_code}\n"