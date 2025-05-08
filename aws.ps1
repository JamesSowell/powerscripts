
function trailRole {

}

# todo notes:
# jq '.[0:20]' gets the first 20 elements! if empty then all!

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

        
        # use this output to pipe with other functions that want the CFN stack name!
        return $stackName
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
$green = [System.ConsoleColor]::Green
$red = [System.ConsoleColor]::DarkRed
$yellow = [System.ConsoleColor]::Yellow
$blue = [System.ConsoleColor]::Blue
$orange = [System.ConsoleColor]::DarkYellow
$default = [System.ConsoleColor]::White
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
}





# it would be cool if since it takes exactly one paramer
# you could pipe `dst 2` -> stackName and let this be the piped input
# into this! so that way yuo could write out your whole thing at once!
function dste {
    param(
        [string]$stackName
    )

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