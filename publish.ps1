param (
    [Parameter(Mandatory)]
    [string]$StartCommitId,
    [Parameter(Mandatory)]
    [string]$CommitId,
    [Parameter(Mandatory)]
    [string]$DownloadFolder = 'downloads',
    [bool]$FolderAsId = $false,
    [bool]$CreateImages = $false
)
 
git diff-tree --no-commit-id --name-only --diff-filter=cd -r "$StartCommitId..$CommitId" | Where-Object { $_.EndsWith('.json') } | Foreach-Object {
 
    $filePath = ($_ | Resolve-Path -Relative) -replace "^./"
    $workspaceFolder = Split-Path -Path $filePath -Parent
    $workspaceFile = $filePath
    Write-Host "folder: $workspaceFolder"
    Write-Host "file: $workspaceFile"
 
    if ( $FolderAsId -eq $true ) {
        $workspaceIdValue = $workspaceFolder
    }
    else {
        $workspaceId = "WORKSPACE_ID_$($workspaceFolder)".ToUpper()
        $workspaceIdValue = (Get-item env:$workspaceId).Value
    }
     
    $workspaceKey = "WORKSPACE_KEY_$($workspaceFolder)".ToUpper()
    $workspaceKeyValue = (Get-item env:$workspaceKey).Value
 
    $workspaceSecret = "WORKSPACE_SECRET_$($workspaceFolder)".ToUpper()
    $workspaceSecretValue = (Get-item env:$workspaceSecret).Value
 
    docker run -i --rm -v ${pwd}:/usr/local/structurizr structurizr/cli push -id $workspaceIdValue -key $workspaceKeyValue -secret $workspaceSecretValue -workspace $workspaceFile
    $outputPath = "$DownloadFolder/$workspaceIdValue"
    if ( $CreateImages -eq $true ) {
        docker run --rm -v ${pwd}:/usr/local/structurizr structurizr/cli export -workspace $workspaceFile -format dot -output $outputPath
        sudo chown ${env:USER}:${env:USER} $outputPath
 
        Write-Host 'Convert exported files to svg'
        Get-ChildItem -Path $outputPath | Foreach-Object {
            $exportPath = ($_ | Resolve-Path -Relative)
            $folder = Split-Path -Path $exportPath -Parent
            $name = Split-Path -Path $exportPath -LeafBase
 
            Write-Host "Writing file: $folder/$name.svg"
            dot -Tsvg $exportPath > $folder/$name.svg
            rm $exportPath
        }
    }
}
