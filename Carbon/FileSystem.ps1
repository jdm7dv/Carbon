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

function New-Junction
{
    <#
    .SYNOPSIS
    Creates a new junction.
    
    .DESCRIPTION
    Creates a junction given by `-Link` which points to the path given by `-Target`.  If something already exists at `Link`, an error is written.  
    
    .EXAMPLE
    New-Junction -Link 'C:\Windows\system32Link' -Target 'C:\Windows\system32'
    
    Creates the `C:\Windows\system32Link` directory, which points to `C:\Windows\system32`.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The new junction to create
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to
        $Target
    )
    
    if( Test-Path $Link -PathType Container )
    {
        Write-Error "'$Link' already exists."
    }
    else
    {
        Write-Host "Creating junction $Link <=> $Target"
        [Carbon.IO.JunctionPoint]::Create( $Link, $Target, $false )
        if( Test-Path $Link -PathType Container ) 
        { 
            Get-Item $Link 
        } 
    }
}

function New-TempDir
{
    $tmpPath = [System.IO.Path]::GetTempPath()
    $newTmpDirName = [System.IO.Path]::GetRandomFileName()
    New-Item (Join-Path $tmpPath $newTmpDirName) -Type directory
}

function Remove-Junction
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove
        $Path
    )
    
    if( Test-PathIsJunction $Path  )
    {
        if( $pscmdlet.ShouldProcess($Path, "remove junction") )
        {
            Write-Host "Removing junction $Path."
            [Carbon.IO.JunctionPoint]::Delete( $Path )
        }
    }
    else
    {
        Write-Error "'$Path' doesn't exist or is not a junction."
    }
}

function Test-PathIsJunction
{
    param(
        [string]
        # The path to check
        $Path
    )
    
    if( Test-Path $Path -PathType Container )
    {
        return (Get-Item $Path).IsJunction
    }
    return $false
}

