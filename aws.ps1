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
            Write-Host "     StackStatus: $($item[1])"
            $i++
        }

        Write-Host "`nTo copy a specific stack's name, run: dst <index>"
    } else {
        Write-Error "not a valid input!"
    }
    

}


function typeChecker {
    param(
        [Parameter(Mandatory)]
        [string]$UserInput
    )

    # Declare a variable to store the parsed integer (even if you don’t use it)
    [int]$nullResult = 0

    if ([int]::TryParse($UserInput, [ref]$nullResult)) {
        Write-Host "You passed an integer: $UserInput"
        return true.exe
    } elseif ($UserInput -match '[a-zA-Z]') {
        Write-Host "You passed an alphabetic string: $UserInput"
    } else {
        Write-Host "Input didn't match any specific type: $UserInput"
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

function nothingChecker {
    param($userInput)
    Write-Host "Nothing was entered"
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
        switch( $resourceStatus){
            "ROLLBACK_COMPLETE" { Set-Color $red }
            "ROLLBACK_FAILED" { Set-Color $red }
            "CREATE_COMPLETE" { Set-Color $green }
            "UPDATE_COMPLETE" { Set-Color $green }
            "CREATE_IN_PROGRESS" { Set-Color $yellow }
            "UPDATE_IN_PROGRESS" { Set-Color $yellow }
            "DELETE_COMPLETE" { Set-Color $green }
            "DELETE_IN_PROGRESS" { Set-Color $yellow }
            "ROLLBACK_IN_PROGRESS" { Set-Color $yellow }
            "CREATE_FAILED" { Set-Color $red }
            "REVIEW_IN_PROGRESS" { Set-Color $orange }
            default { Set-Color $default }
        }


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