



# todo notes:
# jq '.[0:20]' gets the first 20 elements! if empty then all!

function dst {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string]$userInput,
        [switch]$f
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
        # use Write-Output as idiomatically works better for PIPEline instaed of traditional 'return'
        Write-Output $stackName
    } elseif (Is-String($userInput)) {
        $query = "StackSummaries[?contains(StackName,'$userInput')" 
        if ($f){
            $query += " && (StackStatus == 'ROLLBACK_FAILED' || StackStatus == 'CREATE_FAILED' || StackStatus == 'DELETE_FAILED' || StackStatus == 'UPDATE_ROLLBACK_FAILED')"
        }
        $query += "].[StackName, StackStatus]"
        # returns raw JSON string, need to store this into a PS object!
        $global:lastFilteredStacks = aws cloudformation list-stacks `
        --query $query `
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

# it would be cool if since it takes exactly one paramer
# you could pipe `dst 2` -> stackName and let this be the piped input
# into this! so that way yuo could write out your whole thing at once!
function dste {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,              # Accepts unnamed args in this order
            Mandatory = $false,        # Don't prompt for missing input
            ValueFromPipeline = $true  # Accept input from the pipeline
        )]
        [string]$stackName,             # Bind to a string
        [switch]$a
    )

    process {
        # Get stack events
        $events = aws cloudformation describe-stack-events --stack-name $stackName | ConvertFrom-Json

        Write-Debug $events

        # just get the events
        $events = $events.StackEvents


        $failedStates = @(
            "ROLLBACK_FAILED",
            "CREATE_FAILED",
            "DELETE_FAILED",
            "UPDATE_ROLLBACK_FAILED"
        )

        $lastFailedIdx = $events.Count - 1

        if (-not $a) {
            for($i = 0; $i -lt $events.Count; $i++) {
                if ($events[$i].ResourceStatus -in $failedStates) {
                    $lastFailedIdx = $i
                    # isnt printing forsome reason
                    Write-Debug "failed value at $lastFailedIdx"
                }
            }
        }


        # iterate through events and print with color
        $events[0..$lastFailedIdx] | ForEach-Object {
            $resourceStatus = $_.ResourceStatus
            $resourceType = $_.ResourceType

            # Set color based on resourceStatus
            _SetCfnResourceColor($resourceStatus)

            # print ResoruceStatus
            Write-Host "ResouceStatus: $resourceStatus"

            # set color for resourceType
            Set-Color $blue
            Write-Host "ResourceType: $resourceType"

            # reset color to deault
            Set-Color $default
            Write-Host "Timestamp: $($_.Timestamp)"
            Write-Host "LogicalResourceId: $($_.LogicalResourceId)"
            Write-Host "PhysicalResourceId: $($_.PhysicalResourceId)"
            Write-Host "---------------------------------------------"
        }

        # Reset color to default at the end
        Set-Color $default

        Write-Debug "we printed $($lastFailedIdx + 1) values"

    }
}

function dservices {
    param([string]$query)

    $awsHelp = aws help | Out-String
    $lines = $awsHelp -split "`n"

    $inSection = $false
    $rawServices = @()

    foreach($line in $lines) {
        if ($line -match 'AVAILABLE SERVICES') {
            $inSection = $true
        } elseif ($line -match "SEE ALSO") {
            break
        } elseif ($inSection) {
            $rawServices += $line
        }
    }

    # join all lines and split on '*'
    $services = ($rawServices -join " ") -split '\*' | ForEach-Object {
        $_.Trim()
    } | Where-Object { $_ -ne "" }

    $services | Where-Object { $_ -like "*$query*" } ForEach-Object {
        Write-Host $_
    }
}


# slap the ARN that you most care about here and debug away!
function trail {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,              # Accepts unnamed args in this order
            Mandatory = $false,        # Don't prompt for missing input
            ValueFromPipeline = $true  # Accept input from the pipeline
        )]
        [string]$userInput,           
        # may need to change this $s to account for 'AccessKeyId' to see what ResourceName assumer did! (supposedly)
        [switch]$s = $false,                    # indicates that we're looking at 'service'
        [swicth]$d = $false,                    # indicates that we will go 'timeago' in days as opposed to minutes 
        [int]$timeAgo = 30,                 # use to filter through logs given a time period.
        [int]$n = 10                   # maxResults
    )

    # by default we will 

    # Resources will likely be used more. so we'll have this be false by default
    $resourceKey = if(-not $s) {"ResourceName" } else { "EventName" }
    $timeModifierString = if($d) { "AddDays" } else { "AddMinutes" }

    $events = aws cloudtrail look-up events `
    --start-time ((Get-Date).$timeModifierString(-$timeAgo).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")) `
    --end-time ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")) `
    --lookup-attributes AttributeKey=$resourceKey,AttributeValue=$userInput `
    --max-results $n | jq '.Events[] | .CloudTrailEvent | fromjson'


    # pretty print or additional filtering
    $events | ForEach-Object {
        # add stff here later
        Write-Host "----------------"
        Write-Host $events
        Write-Host "----------------"
    }
}

# for trailing an event, like from the osis service or lambda, probably need to add some 
# FUZZY filtering for the service that you are likely debugging.
function trailservice {}



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
        "UPDATE_ROLLBACK_FAILED" { Set-Color $red }
        "CREATE_FAILED" { Set-Color $red }
        "DELETE_FAILED" { Set-Color $red }
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







# validate templates that may exist as a child from this path directory
# function dvt {
#     param (
#         [string]$StartPath = (Get-Location)
#     )

#     Get-ChildItem -Path $StartPath -Recurse -Filter *.template.yml | ForEach-Object {
#         $filePath = $_.FullName
#         Write-Host "🔍 Validating $filePath..."

#         try {
#             $result = aws cloudformation validate-template --template-body file://$filePath | ConvertFrom-Json
#             Write-Host "✅ Valid: $($result.Description)" -ForegroundColor Green
#         } catch {
#             Write-Host "❌ Error validating $filePath" -ForegroundColor Red
#             Write-Host $_.Exception.Message -ForegroundColor DarkRed
#         }

#         # issue here for some reason.
#         Write-Host "" # Blank line for readability
#     }
# }



function dublogin {
    aws-sso-util login
}