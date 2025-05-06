
# Example usage
# gpy -lastLetter "g"
# test -letter "a"

# Function to create solution and test case files
function gpy {
    param (
        [string]$lastLetter
    )
    $lastLetter = $lastLetter.ToLower()
    $asciiLast = [int][char]$lastLetter

    if ($asciiLast -lt 97 -or $asciiLast -gt 122) {
        Write-Host "Error: Please specify a valid letter from a to z."
        return
    }

    $pythonTemplate = @"
import sys
import collections

# Fast input reading
input = sys.stdin.readline

############ ---- Input Functions ---- ############
def inp():
    return(int(input()))
# for taking list inputs
def inlt():
    return(list(map(int,input().split())))
# for taking string inputs, which turns into char array
def insr():
    s = input()
    return(list(s[:len(s) - 1]))
# for taking space separate integer variable inputs
def invr():
    return(map(int,input().split()))


def solve():
    pass  # Implement your solution logic here

def main():
    # platforms will run entire file t times, use t for LOCAL testing
    hasMany = 1
    if hasMany:
        # Reading the number of test cases (t)
        t = int(input())
        for _ in range(t):
            solve()
    else:
        solve()
if __name__ == "__main__":
    main()
"@

    $testCasesTemplate = "1`n5 10`n1 2 3 4 5"

    # Create files from 'a' to specified letter
    for ($asciiCode = 97; $asciiCode -le $asciiLast; $asciiCode++) {
        $letter = [char]$asciiCode
        $solutionFile = "${letter}sol.py"
        $testCaseFile = "${letter}test.txt"

        # Create the Python file with basic template
        Set-Content -Path $solutionFile -Value $pythonTemplate
        Set-Content -Path $testCaseFile -Value $testCasesTemplate
    }

    Write-Host "Files created successfully."
}




# Function to test solution files with test cases
function test {
    param (
        [string]$letter
    )
    $letter = $letter.ToLower()
    $solutionFile = "${letter}sol.py"
    $testCaseFile = "${letter}test.txt"

    # Check if both solution and test files exist
    if (Test-Path $solutionFile) {
        if (Test-Path $testCaseFile) {
            # Read the content of the test case file
            $testInput = Get-Content -Raw -Path $testCaseFile

            # Create a temporary file for piping input (PowerShell doesn't support piping directly into commands)
            $tempInputFile = New-TemporaryFile
            Set-Content -Path $tempInputFile -Value $testInput

            # Run the Python script and pass the temp input file as the argument
            Invoke-Expression "Get-Content $tempInputFile | python3 $solutionFile"

            # Clean up the temp file
            Remove-Item $tempInputFile
        }
        else {
            Write-Host "Error: Test case file $testCaseFile not found."
        }
    }
    else {
        Write-Host "Error: Solution file $solutionFile not found."
    }
}