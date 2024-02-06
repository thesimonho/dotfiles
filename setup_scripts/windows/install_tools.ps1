$tools = @(
    @{repo='BurntSushi/ripgrep'; dir='ripgrep'; pattern='.*x86_64-pc-windows-msvc.zip'; subdir=$true; bindir=''}
    @{repo='jesseduffield/lazygit'; dir='lazygit'; pattern='.*Windows_x86_64.zip'; subdir=$false; bindir=''}
    @{repo='skeeto/w64devkit'; dir='w64devkit'; pattern='w64devkit-\d+.*.zip$'; subdir=$true; bindir='bin'}
)

Function FolderIsInPath($pathToDirectory) {
    $Path = [Environment]::GetEnvironmentVariables("User").Path
    if ( $Path.Split(";").Contains($pathToDirectory) ) {
        return $true
    } else {
        return $false
    }
}

Function AddToPath($pathToDirectory) {
    if ( !(FolderIsInPath($pathToDirectory)) )
    {
        Write-Output " - Adding $pathToDirectory to path"
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        [Environment]::SetEnvironmentVariable("Path", "$currentPath$pathToDirectory;", "User")
    }
}

$toolPath = 'C:\Tools'

# Iterate and download each tool
Write-Output "Downloading tools..."
foreach ($tool in $tools) {
    # Get release link
    $releasesUri = "https://api.github.com/repos/$($tool.repo)/releases/latest"
    Write-Output "* $($tool.repo):"
    
    # Get download link
    $downloadUri = ((Invoke-RestMethod -Method GET -Uri $releasesUri).assets | Where-Object name -match $tool.pattern ).browser_download_url
    Write-Output " - URL: $downloadUri"

    # Download file
    $pathZip = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $(Split-Path -Path $downloadUri -Leaf)
    Invoke-WebRequest -Uri $downloadUri -Out $pathZip

    # Delete existing tool directory
    $pathExtract = Join-Path -Path $toolPath -ChildPath $tool.dir
    Remove-Item -Path $pathExtract -Recurse -Force -ErrorAction SilentlyContinue

    # Unzip
    if ($tool.subdir) {
        # If contents are within a sub directory inside the zip file
        $tempExtract = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $((New-Guid).Guid)
        Expand-Archive -Path $pathZip -DestinationPath $tempExtract -Force
        Move-Item -Path "$tempExtract\*" -Destination $pathExtract -Force
        Remove-Item -Path $tempExtract -Force -Recurse -ErrorAction SilentlyContinue
    }
    else {
        Expand-Archive -Path $pathZip -DestinationPath $pathExtract -Force
    }

    # Add to path
    $binPath = Join-Path -Path $pathExtract -ChildPath $tool.bindir
    AddToPath($binPath)

    # Cleanup
    Remove-Item $pathZip -Force
}

Write-Output "Tools downloaded."
