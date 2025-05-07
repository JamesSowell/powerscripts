function dubstacks {
    param (
        [string]$keyword
    )
    aws cloudformation list-stacks --query "StackSummaries[?contains(StackName,'$keyword')].[StackName, StackStatus]"
}

function dubstack {

}

function trailRole {

}

function dstackgetname {
    param(
        [string]$keyword,
        [int]$index
    )

    if (-not $keyword) {
        Write-Host "Please provide a keyword"
        return
    }
    
    # Giving false negatives not sure why right now
    if (-not $index -or $index -lt 0){
        Write-Host "please provide a valid index (0 or greater)."
        return
    }

    $stackInfo = aws cloudformation list-stacks | jq -r --arg "$keyword" '[.StackSummaries[]] | select(.StackName | contains($keyword)) | [.StackName, .StackStatus]]' | ConvertFrom-Json

    if (-not $stackInfo -or $stackInfo.Count -le $index) {
        Write-Host "No stack found with the keyword '$keyword' at index $index."
    }

    # extract the stack name and status
    $selectedStack = $stackInfo[$index]
    $stackName = $selectedStack[0]
    $stackStatus = $selectedStack[1]

    # copy the stack name to clipboard
    $stackName | Set-Clipboard

    # output the stack name and status
    Write-Host "Stack Name: $stackName"
    Write-Host "Stack Status: $stackStatus"
    
}

function dublogin {
    aws-sso-util login
}