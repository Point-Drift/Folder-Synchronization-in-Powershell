
param (
    [string]$sourcePath,
    [string]$replicaPath,
    [string]$logFilePath
)

# Function to write logs to file and console
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -F "dd-MM-yyyy HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# Function to synchronize folders
function Sync-Folders {
    param (
        [string]$source,
        [string]$replica
    )

    # Create replica folder if it does not exist
    if (-not (Test-Path -Path $replica)) {
        New-Item -ItemType Directory -Path $replica | Out-Null
        Write-Log "Created directory: $replica"
    }

    # Get list of files and folders in source and replica
    $sourceItems = Get-ChildItem -Path $source -Recurse
    $replicaItems = Get-ChildItem -Path $replica -Recurse
    [array]::Reverse($replicaItems)

    # Synchronize files and folders from source to replica
    foreach ($item in $sourceItems) {
        $relativePath = $item.FullName.Substring($source.Length)
        $targetPath = Join-Path -Path $replica -ChildPath $relativePath

        if ($item.PSIsContainer) {
            # Create directories in replica if they do not exist
            if (-not (Test-Path -Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath | Out-Null
                Write-Log "Created directory: $targetPath"
            }
        } else {
            # Copy files to replica
            if (-not (Test-Path -Path $targetPath) -or (Get-Item -Path $targetPath).LastWriteTime -ne $item.LastWriteTime) {
                Copy-Item -Path $item.FullName -Destination $targetPath -Force
                Write-Log "Copied file: $($item.FullName) to $targetPath"
            }
        }
    }
    

    # Remove files and folders in replica that do not exist in source
    foreach ($item in $replicaItems) {
        $relativePath = $item.FullName.Substring($replica.Length)
        $sourcePathEquivalent = Join-Path -Path $source -ChildPath $relativePath

        if (-not (Test-Path -Path $sourcePathEquivalent)) {
            if ($item.PSIsContainer) {
                Remove-Item -Path $item.FullName -Recurse -Force
                Write-Log "Removed directory: $($item.FullName)"
            } else {
                Remove-Item -Path $item.FullName -Force
                Write-Log "Removed file: $($item.FullName)"
            }
        }
    }
}




if (-not (Test-Path -Path  $logFilePath)) { # if log file folder does not exist create it and the log file
    
    New-Item -ItemType Directory -Path  $logFilePath | Out-Null

    
    $logFile = "$logFilePath\SynchLog $(get-date -f "dd-MM-yyyy HH.mm.ss").txt" #logfile is the path to the file itself
    New-Item $logFile | Out-Null
    
    Write-Log "Created directory:  $logFilePath"
    Write-Log "Log File $logFile created"

}else{ #if the log file folder exists create $logfile create the file and log entry
    
    $logFile = "$logFilePath\SynchLog $(get-date -f "dd-MM-yyyy HH.mm.ss").txt"
    New-Item $logFile | Out-Null
    
    Write-Log "Log File $logFile created"

}



# Start synchronization process
Write-Log "Starting synchronization from $sourcePath to $replicaPath"
Sync-Folders -source $sourcePath -replica $replicaPath
Write-Log "Synchronization completed"