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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([Collections.Hashtable])]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]
        # The name of the environment variable.
		$Name,

		[string]
        # the value of the environment variable.        
		$Value,

		[ValidateSet("Present","Absent")]
		[string]
        # Create or delete the resource?
		$Ensure
	)
    
    Set-StrictMode -Version 'Latest'

    $actualValue = [Environment]::GetEnvironmentVariable($Name,[EnvironmentVariableTarget]::Machine)

    $Ensure = 'Present'
    if( $actualValue -eq $null )
    {
        $Ensure = 'Absent'
    }

    Write-Verbose ('{0} = {1}' -f $Name,$actualValue)
    @{
        Name = $Name;
        Ensure = $Ensure;
        Value = $actualValue;
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]
		$Name,

		[string]
		$Value,

		[Parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[string]
		$Ensure
	)

    Set-StrictMode -Version 'Latest'

    Write-Verbose ('{0} environment variable {1} value to {2}' -f $Ensure,$Name,$Value)

    [Environment]::SetEnvironmentVariable($Name,$null,([EnvironmentVariableTarget]::Machine))
    [Environment]::SetEnvironmentVariable($Name,$null,([EnvironmentVariableTarget]::Process))

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('Setting environment variable {0} = {1}.' -f $Name,$Value)
        Set-EnvironmentVariable -Name $Name -Value $Value -ForComputer -ForProcess
    }

}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[String]
		$Name,

		[String]
		$Value,

		[ValidateSet("Present","Absent")]
		[String]
		$Ensure
	)

    Set-StrictMode -Version 'Latest'
    Write-Verbose ('Getting current value of ''{0}'' environment variable.' -f $Name)

    $resource = $null
    $resource = Get-TargetResource -Name $Name
    if( -not $resource )
    {
        Write-Verbose ('Environment variable ''{0}'' not found.' -f $Name)
        return $false
    }

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('{0} -eq {1}' -f $resource.Value,$Value)
        return ($resource.Value -eq $Value);
    }
    else
    {
        Write-Verbose ('{0}: {1}' -f $Name,$Value)
        return ($resource.Value -eq $null)
    }

    $false
}

Export-ModuleMember -Function '*-TargetResource'
