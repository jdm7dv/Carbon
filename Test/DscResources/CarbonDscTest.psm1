# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$CarbonDscOutputRoot = $null

function Start-CarbonDscTestFixture
{

    $tempDir = [IO.Path]::GetRandomFileName()
    $tempDir = 'CarbonDscTest-{0}-{1}' -f $Name,$tempDir
    $script:CarbonDscOutputRoot = Join-Path -Path $env:TEMP -ChildPath $tempDir

    New-Item -Path $CarbonDscOutputRoot -ItemType 'directory'

    Clear-DscLocalResourceCache
}

function Stop-CarbonDscTestFixture
{

    if( (Test-Path -Path $CarbonDscOutputRoot -PathType Container) )
    {
        Remove-Item -Path $CarbonDscOutputRoot -Recurse
    }
}

function Invoke-CarbonTestDscConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    Set-StrictMode -Off


    & $Name -OutputPath $tempDir

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Verbose:$VerbosePreference
}

function Assert-DscResourcePresent
{
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Resource
    )

    Set-StrictMode -Version 'Latest'

    Assert-Equal 'Present' $Resource.Ensure
}

function Assert-DscResourceAbsent
{
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Resource
    )

    Set-StrictMode -Version 'Latest'

    Assert-Equal 'Absent' $Resource.Ensure
}


Export-ModuleMember -Function '*-*' -Variable 'CarbonDscOutputRoot'