Param (
    [string]$version = "dev"
)
$ErrorActionPreference = "Stop"

Write-Output "Running PSBuild.ps1..."
Write-Output "" 
$target=".\deploy\xelogstash"
Write-Output "Target:  $target"

Write-Output "Version: $($version)"

# $now = Get-Date -UFormat "%Y-%m-%d_%T_%Z"
$now = Get-Date -Format "yyyy'-'MM'-'dd'T'HH':'mm':'sszzz"
$sha1 = (git describe --tags --dirty --always).Trim()
Write-Output "Git:     $sha1"
Write-Output "Build:   $now"

Write-Output "" 
Write-Output "Running go vet..."
go vet -all .\cmd\xelogstash
if ($LastExitCode -ne 0) {
    exit
}

go vet -all .\cmd\xewriter
if ($LastExitCode -ne 0) {
    exit
}

go vet -all .\config .\log .\logstash .\seq .\status .\summary .\xe .\sink .\pkg\...
if ($LastExitCode -ne 0) {
    exit
}

Write-Output "Running go test..."
go test .\cmd\xelogstash .\config .\seq .\xe .\sink .\status .\pkg\...
if ($LastExitCode -ne 0) {
    exit
}

Write-Output "Building xelogstash..."
go build -o "$($target)\xelogstash.exe" -a -ldflags "-X main.sha1ver=$sha1 -X main.buildTime=$now -X main.version=$version" ".\cmd\xelogstash"
if ($LastExitCode -ne 0) {
    exit
}

Write-Output "Building xewriter..."
go build -o "$($target)\xewriter.exe" -a -ldflags "-X main.sha1ver=$sha1 -X main.buildTime=$now -X main.version=$version" ".\cmd\xewriter"
if ($LastExitCode -ne 0) {
    exit
}

Write-Output "Copying Files..."
Copy-Item -Path ".\samples\*.toml"          -Destination $target
Copy-Item -Path ".\samples\*.sql"           -Destination $target
Copy-Item -Path ".\samples\minimum.batch"   -Destination $target
Copy-Item -Path ".\README.md"               -Destination $target

Write-Output "Done."
