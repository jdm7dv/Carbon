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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

Describe 'Test-PathIsJunction' {
    
    function Invoke-TestPathIsJunction($path)
    {
        return Test-PathIsJunction $path
    }

    BeforeEach {
        $Global:Error.Clear()
    }
    
    It 'should know files are not reparse points' {
        $result = Test-PathIsJunction $PSCommandPath
        $result | Should Be $false
    }
    
    It 'should know directories are not reparse points' {
        $result = Invoke-TestPathIsJunction $PSScriptRoot
        $result | Should Be $false
    }
    
    It 'should detect a reparse point' {
        $reparsePath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
        New-Junction $reparsePath $PSScriptRoot
        $result = Invoke-TestPathIsJunction $reparsePath
        $result | Should Be $true
        Remove-Junction $reparsePath
    }
    
    It 'should handle non existent path' {
        $result = Invoke-TestPathIsJunction ([IO.Path]::GetRandomFileName())
        $result | Should Be $false
        $error.Count | Should Be 0
    }
    
    It 'should handle hidden file' {
        $tempDir = New-TempDir -Prefix (Split-Path -Leaf -Path $PSCommandPath)
        $tempDir.Attributes = $tempDir.Attributes -bor [IO.FileAttributes]::Hidden
        $result = Invoke-TestPathIsJunction $tempDir
        $result | Should Be $false
        $Global:Error.Count | Should Be 0
    }
    
}
