function dubstacks {
    param (
        [string]$keyword
    )
    aws cloudformation list-stacks --query "StackSummaries[?contains(StackName,'$keyword')].[StackName, StackStatus]"
}