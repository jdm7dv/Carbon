
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force

function Start-TestFixture
{
    Start-CarbonDscTestFixture
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\DscResources\Carbon_EnvironmentVariable' -Resolve) -Force
    [Environment]::SetEnvironmentVariable('fubar',$null,'Machine')
    [Environment]::SetEnvironmentVariable('fubar',$null,'Process')
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
    Remove-Module 'Carbon_EnvironmentVariable'
    [Environment]::SetEnvironmentVariable('fubar',$null,'Machine')
    [Environment]::SetEnvironmentVariable('fubar',$null,'Process')
}

function Test-TestTargetResource
{
    Assert-False (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Present')
    Assert-True (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Absent')
    Assert-True (Test-TargetResource -Name 'Path' -Value ([Environment]::GetEnvironmentVariable('Path','Machine')) -Ensure 'Present')
    Assert-False (Test-TargetResource -Name 'Path' -Value ([Environment]::GetEnvironmentVariable('Path','Machine')) -Ensure 'Absent')
}

function Test-GetTargetResource
{
    $resource = Get-TargetResource -Name 'fubar'
    Assert-NotNull $resource
    Assert-Equal 'fubar' $resource.Name
    Assert-DscResourceAbsent $resource
    Assert-null $resource.Value

    $resource = Get-TargetResource -Name 'TEMP'
    Assert-NotNull $resource
    Assert-Equal 'TEMP' $resource.Name
    Assert-DscResourcePresent $resource
    Assert-Equal ([Environment]::GetEnvironmentVariable('TEMP','Machine')) $resource.Value
}

function Test-SetTargetResource
{
    $value = [Guid]::NewGuid().ToString()
    Set-TargetResource -Name 'fubar' -Value $value -Ensure 'Present'

    Assert-Equal ([Environment]::GetEnvironmentVariable('fubar','Machine')) $value
    Assert-Equal ([Environment]::GetEnvironmentVariable('fubar','Process')) $value

    Set-TargetResource -Name 'fubar' -Ensure 'Absent'
}

configuration ShouldSetEnvironmentVariable
{
    param(
        $Value,
        $Ensure
    )

    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        EnvironmentVariable setEnvVariable
        {
            Name = 'CarbonDscEnvironmentVariable';
            Value = $Value;
            Ensure = $Ensure;
        }
    }
}
function Test-ShouldRunThroughDsc
{
    $value = [Guid]::NewGuid().ToString()

    & ShouldSetEnvironmentVariable -Value $value -Ensure 'Present' -OutputPath $CarbonDscOutputRoot

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-EnvironmentVariable 'CarbonDscEnvironmentVariable' $value

    & ShouldSetEnvironmentVariable -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-EnvironmentVariable 'CarbonDscEnvironmentVariable' $null
}

function Assert-EnvironmentVariable
{
    param(
        $Name,
        $Value
    )

    Set-StrictMode -Version 'Latest'

    $stdOutPath = Join-Path -Path $env:Temp -ChildPath ([IO.Path]::GetRandomFileName())
    $stderrPath = Join-Path -Path $env:Temp -ChildPath ([IO.Path]::GetRandomFileName())
    ($stdoutpath,$stderrPath) | ForEach-Object { New-Item -ItemType 'File' -Path $_ } | Out-Null
    try
    {
        Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c',('echo %{0}%' -f $Name)) -UseNewEnvironment -Wait -RedirectStandardError $stderrPath -RedirectStandardOutput $stdOutPath -NoNewWindow
        $stderr = Get-Content -Path $stderrPath -Raw #-Encoding BigEndianUnicode
        Assert-Null $stdErr
        $stdout = Get-Content -Path $stdOutPath -Raw
        $stdout = $stdout.Trim()
        if( $value -eq $null )
        {
            Assert-Equal ('%{0}%' -f $Name) $stdout
        }
        else
        {
            Assert-Equal $value $stdout
        }
    }
    finally
    {
        ($stdoutpath,$stderrPath) | Where-Object { Test-Path -Path $_ -PathType leaf } | Remove-Item
    }

}