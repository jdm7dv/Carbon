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

[CmdletBinding()]
param(
    [Switch]
    $ForDsc
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

if( $env:COMPUTERNAME -eq $env:USERNAME )
{
    throw ('Can''t run Carbon tests. The current user''s username ({0}) is the same as the computer name ({1}). This causes problems with resolving identities, getting items from the registry, etc. Please re-run these tests using a different account.')
}

$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

if( (Test-Path -Path 'env:APPVEYOR') )
{
    # On the build server, files never change, so we only ever need to import Carbon once.
    if( -not (Get-Module -Name 'Carbon') )
    {
        & $importCarbonPath -Force
    }
}
else 
{
    # On developer computers, only import Carbon if it has changed since the last import.
    if( -not (Test-Path -Path 'variable:CarbonLastImportedAt') )
    {
        $Global:CarbonLastImportedAt = [DateTime]::MinValue
    }

    $mostRecentModificationAt = 
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon') -File -Recurse |
        Sort-Object -Property 'LastWriteTime' -Descending |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'LastWriteTime'

    $moduleImported = $null -ne (Get-Module -Name 'Carbon')
    $moduleUpdated = $mostRecentModificationAt -gt $CarbonLastImportedAt
    if( -not $moduleImported -or $moduleUpdated )
    {
        Write-Verbose -Message ('Importing Carbon.') -Verbose
        Write-Verbose -Message ('Module Already Imported?            {0}' -f $moduleImported) -Verbose
        Write-Verbose -Message ('Module Modified Since Last Import?  {0}' -f $moduleUpdated) -Verbose
        Write-Verbose -Message ('              CarbonLastImportedAt  {0}' -f $CarbonLastImportedAt) -Verbose
        Write-Verbose -Message ('                LastModificationAt  {0}' -f $mostRecentModificationAt) -Verbose
        & $importCarbonPath -Force
        $Global:CarbonLastImportedAt = Get-Date
    }
}

if( $ForDsc )
{
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force
}
else
{
    if( (Get-Module -Name 'CarbonDscTest') )
    {
        Remove-Module -Name 'CarbonDscTest' -Force
    }
}
