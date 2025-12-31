function Import-IntuneW365ProvisioningPolicy {
    <#
    .SYNOPSIS
        Imports Windows 365 provisioning policies from JSON templates
    .DESCRIPTION
        Reads JSON templates from Templates/W365 and creates Cloud PC provisioning policies via Graph API.
        Resolves gallery image display names to image IDs at runtime.
    .PARAMETER TemplatePath
        Path to the provisioning policy template file (defaults to Templates/W365/ProvisioningPolicy.json)
    .PARAMETER RemoveExisting
        Remove existing hydration kit provisioning policies before import
    .EXAMPLE
        Import-IntuneW365ProvisioningPolicy
        Imports provisioning policies from default template location
    .EXAMPLE
        Import-IntuneW365ProvisioningPolicy -WhatIf
        Preview what would be created without making changes
    .EXAMPLE
        Import-IntuneW365ProvisioningPolicy -RemoveExisting
        Remove existing hydration kit policies before importing
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$TemplatePath,

        [Parameter()]
        [switch]$RemoveExisting
    )

    $results = @()
    $resourceType = 'W365ProvisioningPolicy'
    $endpoint = 'beta/deviceManagement/virtualEndpoint/provisioningPolicies'

    # Set default template path
    if (-not $TemplatePath) {
        $TemplatePath = Join-Path $script:TemplatesPath 'W365/ProvisioningPolicy.json'
    }

    # Prefetch existing provisioning policies with pagination
    $existingPolicies = @{}
    try {
        $listUri = $endpoint
        do {
            $response = Invoke-MgGraphRequest -Method GET -Uri $listUri -ErrorAction Stop
            foreach ($policy in $response.value) {
                if ($policy.displayName -and -not $existingPolicies.ContainsKey($policy.displayName)) {
                    $existingPolicies[$policy.displayName] = @{
                        Id = $policy.id
                        Description = $policy.description
                    }
                }
            }
            $listUri = $response.'@odata.nextLink'
        } while ($listUri)
    }
    catch {
        $errMessage = Get-GraphErrorMessage -ErrorRecord $_
        Write-Warning "Failed to list existing W365 provisioning policies: $errMessage"
    }

    # Handle RemoveExisting
    if ($RemoveExisting) {
        foreach ($policyName in $existingPolicies.Keys) {
            $policyInfo = $existingPolicies[$policyName]

            # Safety check: Only delete if created by this kit
            if (-not (Test-HydrationKitObject -Description $policyInfo.Description -ObjectName $policyName)) {
                Write-Verbose "Skipping '$policyName' - not created by Intune-Hydration-Kit"
                continue
            }

            if ($PSCmdlet.ShouldProcess($policyName, 'Delete W365 provisioning policy')) {
                try {
                    Invoke-MgGraphRequest -Method DELETE -Uri "$endpoint/$($policyInfo.Id)" -ErrorAction Stop
                    Write-HydrationLog -Message "  Deleted: $policyName" -Level Info
                    $results += New-HydrationResult -Name $policyName -Type $resourceType -Action 'Deleted' -Status 'Success'
                }
                catch {
                    $errMessage = Get-GraphErrorMessage -ErrorRecord $_
                    Write-HydrationLog -Message "  Failed: $policyName - $errMessage" -Level Warning
                    $results += New-HydrationResult -Name $policyName -Type $resourceType -Action 'Failed' -Status "Delete failed: $errMessage"
                }
            }
            else {
                Write-HydrationLog -Message "  WouldDelete: $policyName" -Level Info
                $results += New-HydrationResult -Name $policyName -Type $resourceType -Action 'WouldDelete' -Status 'DryRun'
            }
        }
        return $results
    }

    # Load template
    if (-not (Test-Path $TemplatePath)) {
        Write-Warning "W365 provisioning policy template not found: $TemplatePath"
        return $results
    }

    $template = Get-Content -Path $TemplatePath -Raw -Encoding utf8 | ConvertFrom-Json
    $displayName = $template.displayName

    if (-not $displayName) {
        Write-Warning "Template missing displayName: $TemplatePath"
        $results += New-HydrationResult -Name (Split-Path $TemplatePath -Leaf) -Path $TemplatePath -Type $resourceType -Action 'Failed' -Status 'Missing displayName'
        return $results
    }

    # Check if already exists
    if ($existingPolicies.ContainsKey($displayName)) {
        Write-HydrationLog -Message "  Skipped: $displayName" -Level Info
        $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'Skipped' -Status 'Already exists'
        return $results
    }

    # Resolve gallery image by display name if needed
    $importBody = Copy-DeepObject -InputObject $template
    if ($importBody.imageDisplayName -and $importBody.imageType -eq 'gallery') {
        try {
            $galleryImages = Invoke-MgGraphRequest -Method GET -Uri 'beta/deviceManagement/virtualEndpoint/galleryImages' -ErrorAction Stop
            $matchingImage = $galleryImages.value | Where-Object { $_.displayName -like "*$($importBody.imageDisplayName)*" } | Select-Object -First 1

            if ($matchingImage) {
                $importBody | Add-Member -NotePropertyName 'imageId' -NotePropertyValue $matchingImage.id -Force
                Write-Verbose "Resolved image '$($importBody.imageDisplayName)' to ID: $($matchingImage.id)"
            }
            else {
                $availableImages = ($galleryImages.value | Select-Object -ExpandProperty displayName) -join ', '
                Write-Warning "Gallery image '$($importBody.imageDisplayName)' not found. Available: $availableImages"
                $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'Failed' -Status "Gallery image not found: $($importBody.imageDisplayName)"
                return $results
            }
        }
        catch {
            $errMessage = Get-GraphErrorMessage -ErrorRecord $_
            Write-Warning "Failed to query gallery images: $errMessage"
            $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'Failed' -Status "Gallery image query failed: $errMessage"
            return $results
        }

        # Remove the helper property before sending
        if ($importBody.PSObject.Properties['imageDisplayName']) {
            $null = $importBody.PSObject.Properties.Remove('imageDisplayName')
        }
    }

    Remove-ReadOnlyGraphProperties -InputObject $importBody

    # Add hydration kit marker to description
    $existingDesc = if ($importBody.description) { $importBody.description } else { "" }
    $importBody.description = if ($existingDesc) { "$existingDesc - Imported by Intune-Hydration-Kit" } else { "Imported by Intune-Hydration-Kit" }

    # Create policy
    if ($PSCmdlet.ShouldProcess($displayName, 'Create W365 provisioning policy')) {
        try {
            $null = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body ($importBody | ConvertTo-Json -Depth 10) -ContentType 'application/json' -ErrorAction Stop
            Write-HydrationLog -Message "  Created: $displayName" -Level Info
            $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'Created' -Status 'Success'
        }
        catch {
            $errMessage = Get-GraphErrorMessage -ErrorRecord $_
            Write-HydrationLog -Message "  Failed: $displayName - $errMessage" -Level Warning
            $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'Failed' -Status $errMessage
        }
    }
    else {
        Write-HydrationLog -Message "  WouldCreate: $displayName" -Level Info
        $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'WouldCreate' -Status 'DryRun'
    }

    return $results
}
