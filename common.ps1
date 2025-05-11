
# Alises
Set-Alias vim nvim
Set-Alias ll ls
Set-Alias cs clear
Set-Alias grep findstr
Set-Alias -Name rl -Value Invoke-History

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

function whereis ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function editprofile {
    code $PROFILE
}

function talonuser {
    Set-Location $HOME\AppData\Roaming\talon\user
}

# node
function nomodules {
    Get-ChildItem -Path . -Recurse -Directory -Name node_modules | ForEach-Object {
        Remove-Item -Recurse -Force $_
    }
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





# obsidian
function obs {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VaultName
    )
    
    Start-Process "obsidian://open?vault=$VaultName"
}



# 
# curl.exe -s https://api.github.com/repos/jqlang/jq | jq '{ yessith: .owner.login, noith: .network_count } '
