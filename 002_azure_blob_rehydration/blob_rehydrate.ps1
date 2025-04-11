param (
    [string]$accountName,
    [string]$containerName
)

if (-not $accountName) {
    $accountName = Read-Host "# Enter demo storage account name"
}
if (-not $containerName) {
    $containerName = Read-Host "# Enter demo storage account's container name"
}

if ([string]::IsNullOrWhiteSpace($accountName) -or [string]::IsNullOrWhiteSpace($containerName)) {
    Write-Error "Both account name and container name are required. Exiting..."
    exit 1
}

# List blobs in the specified container
try {
    $blobs = az storage blob list `
        --account-name $accountName `
        --container-name $containerName `
        --auth-mode login `
        --query "[].name" -o tsv
} catch {
    Write-Error "Failed to list blobs. Error: $_"
    exit 1
}

# Loop through blobs
foreach ($blob in $blobs -split "`n") {
    $blob = $blob.Trim()
    if (-not [string]::IsNullOrWhiteSpace($blob)) {
        Write-Host "`nProcessing blob: $blob"

        try {
            $currentTier = az storage blob show `
                --account-name $accountName `
                --container-name $containerName `
                --name "$blob" `
                --auth-mode login `
                --query "properties.blobTier" `
                -o tsv

            Write-Host "Current access tier: $currentTier"
        } catch {
            Write-Warning "Could not retrieve tier for blob '$blob'. Skipping. Error: $_"
            continue
        }

        if ($currentTier -eq "Archive") {
            Write-Host "Rehydrating $blob to COOL..."
            try {
                az storage blob set-tier `
                    --account-name $accountName `
                    --container-name $containerName `
                    --name "$blob" `
                    --tier Cool `
                    --rehydrate-priority High `
                    --auth-mode login `
                    --only-show-errors
                Write-Host "Rehydration initiated for: $blob"
            } catch {
                Write-Warning "Failed to rehydrate blob '$blob'. Error: $_"
            }
        } else {
            Write-Host "No rehydration needed for $blob"
        }
    }
}
