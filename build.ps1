param(
    $version = "7.7.3",
    $packageVersion = $null,
    $nugetApiKey = $null
)
if (!$packageVersion) {
    $script:packageVersion = $version
}
$filename = "node-v$($version)-win-x64.zip"
$nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$url = "https://nodejs.org/dist/latest/node-v$($version)-win-x64.zip"

Write-Output "Cleaning..."
Remove-Item tools -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item *.nuspec -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item node-v*-win-x64 -Recurse -Force -ErrorAction SilentlyContinue

if (!(Test-Path "nuget.exe")) {
    Write-Output "Downloading nuget.exe..."
    Invoke-WebRequest -Uri $nugetUrl -OutFile "nuget.exe"
}

if (!(Test-Path $filename)) {
    Write-Output "Downloading $filename..."
    Invoke-WebRequest -Uri $url -OutFile $filename
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
Write-Output "Extracting $filename..."

[System.IO.Compression.ZipFile]::ExtractToDirectory($filename, ".\")

New-Item .\tools\node_modules\npm\bin -ItemType "directory" -ErrorAction SilentlyContinue
Copy-Item ".\node-v$($version)-win-x64\*.*" .\tools\
Copy-Item ".\node-v$($version)-win-x64\node_modules\npm\bin\*.*" .\tools\node_modules\npm\bin\ -Recurse

Write-Output "Removing extra stuff from npm"
Remove-Item .\tools\node_modules\npm\* -Exclude "bin\*" -Recurse -Force

$nuspec = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd">
    <metadata>
        <id>Nodejs.Redist.x64</id>
        <version>$packageVersion</version>
        <authors>mihasic</authors>
        <owners>mihasic</owners>
        <licenseUrl>https://github.com/nodejs/node/blob/master/LICENSE</licenseUrl>
        <projectUrl>https://github.com/mihasic/NodejsRedist</projectUrl>
        <requireLicenseAcceptance>false</requireLicenseAcceptance>
        <developmentDependency>true</developmentDependency>
        <description>NodeJS $version for Win x64 to embed in build scripts.</description>
        <summary>NodeJS to embed in build scripts.</summary>
        <copyright>mihasic 2017</copyright>
        <tags>nodejs x64</tags>
    </metadata>
    <files>
        <file src="tools\**" target="tools" />
    </files>
</package>
"@

Write-Output "Creating package..."

([xml]$nuspec).Save("the.nuspec")

Write-Output "Creating package..."
.\NuGet.exe pack .\the.nuspec -version $packageVersion

if ($nugetApiKey) {
    .\nuget.exe push "Nodejs.Redist.x64.$packageVersion.nupkg" $nugetApiKey -source https://api.nuget.org/v3/index.json
}