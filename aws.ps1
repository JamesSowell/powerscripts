function dstacks {
    param (
        [string]$keyword,
        [int]$maxResults
    )
    if ( -not $maxResults ){
        $maxResults = 10
    }
    
    aws cloudformation list-stacks --query "StackSummaries[?contains(StackName,'$keyword')].[StackName, StackStatus]" --max-results $maxResults
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


function dstackevent {
    param(
        [string]$stackName
    )

    # define colors
    $red = [System.ConsoleColor]::Red
    $green = [System.ConsoleColor]::Green
    $yellow = [System.ConsoleColor]::Yellow
    $blue = [System.ConsoleColor]::Blue
    $orange = [System.ConsoleColor]::Orange
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
        $resouceType = $event.ResourceType

        # Set color based on resourceStatus
        switch( $resource){
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
        Write-Host "ResouceType: $resourceType"

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