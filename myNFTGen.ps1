param (
    [string]$Name,
    [string]$Description,
    [string]$ImageURL
)

# Example NFT metadata
$nftMetadata = @{
    Name = $Name
    Description = $Description
    Image = $ImageURL
}

# Convert metadata to JSON
$nftMetadataJson = $nftMetadata | ConvertTo-Json

# Save metadata to a file
$nftMetadataJson | Out-File -FilePath "nft_metadata.json"

Write-Host "NFT metadata saved to nft_metadata.json"
