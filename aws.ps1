function dstacks {
    param (
        [string]$keyword,
        [int]$maxResults
    )
    if ( -not $maxResults ){
        $maxResults = 10
    }
    
    aws cloudformation list-stacks --query "StackSummaries[?contains(StackName,'$keyword')].[StackName, StackStatus]" 
    # check if there's a limit flag we cna use in lieu of this
    # --max-results $maxResults
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
    # if (-not $index -or $index -lt 0){
    #     Write-Host "please provide a valid index (0 or greater)."
    #     return
    # }

    $stackInfo = aws cloudformation list-stacks | jq -r --arg keyword "$keyword" '[.StackSummaries[] | select(.StackName | contains($keyword)) | [.StackName, .StackStatus]]' | ConvertFrom-Json

    if (-not $stackInfo -or $stackInfo.Count -le $index) {
        Write-Host "No stack found with the keyword '$keyword' at index $index."
        return
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

function dst {
    param (
        [string]$userInput
    )
    
    # if given a number, then pull from the persisted values....
    if (Is-Integer($userInput) -and $userInput -lt $global:lastFilteredStacks.Count) {
        # pull from the global!
        # extract the stack name and status
        $index = $userInput
        $selectedStack = $global:lastFilteredStacks[$index]
        $stackName = $selectedStack[0]
        $stackStatus = $selectedStack[1]

        # copy the stack name to clipboard
        $stackName | Set-Clipboard

        # output the stack name and status
        Write-Host "Stack Name: $stackName"
        Write-Host "Stack Status: $stackStatus"
    } elseif (Is-String($userInput)) {
        # returns raw JSON string, need to store this into a PS object!
        $global:lastFilteredStacks = aws cloudformation list-stacks `
        --query "StackSummaries[?contains(StackName,'$userInput')].[StackName, StackStatus]" `
        --output json | ConvertFrom-Json
        # perform jq on the response such that we can see it better
        $i = 0
        foreach($item in $global:lastFilteredStacks) {
            Write-Host "[$i] StackName: $($item[0])"
            _SetCfnResourceColor($item[1])
            Write-Host "     StackStatus: $($item[1])"
            $i++
            Set-Color $global:default 
        }

        Write-Host "`nTo copy a specific stack's name, run: dst <index>"
    } else {
        Write-Error "not a valid input!"
    }
    

}




# Helper functions
function Is-Integer {
    param([string]$userInput)

    [int]$tmp = 0
    return [int]::TryParse($userInput, [ref]$tmp)
}

function Is-Natural {
    param($number)
    return Is-Integer($number) -and $number -ge 0
}

function Is-String {
    param($userInput)
    return $userInput -is [string]
}


# if this doesn't work we might need the $global: prefixing all of them.
# define colors
$global:green = [System.ConsoleColor]::Green
$global:red = [System.ConsoleColor]::DarkRed
$global:yellow = [System.ConsoleColor]::Yellow
$global:blue = [System.ConsoleColor]::Blue
$global:orange = [System.ConsoleColor]::DarkYellow
$global:default = [System.ConsoleColor]::White
# Function to set color
function Set-Color {
    param(
        [System.ConsoleColor]$color
    )
    [System.Console]::ForegroundColor = $color
}


# AWS helpers
function _SetCfnResourceColor {
    param([string]$resourceStatus)
    # Set color based on resourceStatus
    switch( $resourceStatus){
        "ROLLBACK_COMPLETE" { Set-Color $global:red }
        "ROLLBACK_FAILED" { Set-Color $global:red }
        "CREATE_COMPLETE" { Set-Color $global:green }
        "UPDATE_COMPLETE" { Set-Color $global:green }
        "CREATE_IN_PROGRESS" { Set-Color $global:yellow }
        "UPDATE_IN_PROGRESS" { Set-Color $global:yellow }
        "DELETE_COMPLETE" { Set-Color $global:green }
        "DELETE_IN_PROGRESS" { Set-Color $global:yellow }
        "ROLLBACK_IN_PROGRESS" { Set-Color $global:yellow }
        "CREATE_FAILED" { Set-Color $global:red }
        "REVIEW_IN_PROGRESS" { Set-Color $global:orange }
        default { Set-Color $global:default }
    }    
}






function dstackevent {
    param(
        [string]$stackName
    )

    # define colors
    $red = [System.ConsoleColor]::DarkRed
    $green = [System.ConsoleColor]::Green
    $yellow = [System.ConsoleColor]::Yellow
    $blue = [System.ConsoleColor]::Blue
    $orange = [System.ConsoleColor]::DarkYellow
    $default = [System.ConsoleColor]::White

    # Get stack events
    $events = aws cloudformation describe-stack-events --stack-name $stackName | ConvertFrom-Json
    # Function to set color
    function Set-Color {
        param(
            [System.ConsoleColor]$color
        )
        [System.Console]::ForegroundColor = $color
    }

    # iterate through events and print with color
    foreach ($event in $events.StackEvents) {
        $resourceStatus = $event.ResourceStatus
        $resourceType = $event.ResourceType

        # Set color based on resourceStatus
        _SetCfnResourceColor($resourceStatus)


        # print ResoruceStatus
        Write-Host "ResouceStatus: $resourceStatus"

        # set color for resourceType
        Set-Color $blue
        Write-Host "ResourceType: $resourceType"

        # reset color to deault
        Set-Color $default
        Write-Host "Timestamp: $($event.Timestamp)"
        Write-Host "LogicalResourceId: $($event.LogicalResourceId)"
        Write-Host "PhysicalResourceId: $($event.PhysicalResourceId)"
        Write-Host "---------------------------------------------"
    }

    # Reset color to default at the end
    Set-Color $default
}

function dublogin {
    aws-sso-util login
}