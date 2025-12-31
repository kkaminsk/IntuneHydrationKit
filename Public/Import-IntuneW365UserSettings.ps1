function Import-IntuneW365UserSettings {
    <#
    .SYNOPSIS
        Imports Windows 365 user settings from JSON templates
    .DESCRIPTION
        Reads JSON templates from Templates/W365 and creates Cloud PC user settings via Graph API.
    .PARAMETER TemplatePath
        Path to the user settings template file (defaults to Templates/W365/UserSettings.json)
    .PARAMETER RemoveExisting
        Remove existing hydration kit user settings before import
    .EXAMPLE
        Import-IntuneW365UserSettings
        Imports user settings from default template location
    .EXAMPLE
        Import-IntuneW365UserSettings -WhatIf
        Preview what would be created without making changes
    .EXAMPLE
        Import-IntuneW365UserSettings -RemoveExisting
        Remove existing hydration kit settings before importing
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$TemplatePath,

        [Parameter()]
        [switch]$RemoveExisting
    )

    $results = @()
    $resourceType = 'W365UserSettings'
    $endpoint = 'beta/deviceManagement/virtualEndpoint/userSettings'

    # Set default template path
    if (-not $TemplatePath) {
        $TemplatePath = Join-Path $script:TemplatesPath 'W365/UserSettings.json'
    }

    # Prefetch existing user settings with pagination
    $existingSettings = @{}
    try {
        $listUri = $endpoint
        do {
            $response = Invoke-MgGraphRequest -Method GET -Uri $listUri -ErrorAction Stop
            foreach ($setting in $response.value) {
                if ($setting.displayName -and -not $existingSettings.ContainsKey($setting.displayName)) {
                    $existingSettings[$setting.displayName] = @{
                        Id = $setting.id
                        Description = $setting.description
                    }
                }
            }
            $listUri = $response.'@odata.nextLink'
        } while ($listUri)
    }
    catch {
        $errMessage = Get-GraphErrorMessage -ErrorRecord $_
        Write-Warning "Failed to list existing W365 user settings: $errMessage"
    }

    # Handle RemoveExisting
    if ($RemoveExisting) {
        foreach ($settingName in $existingSettings.Keys) {
            $settingInfo = $existingSettings[$settingName]

            # Safety check: Only delete if created by this kit
            if (-not (Test-HydrationKitObject -Description $settingInfo.Description -ObjectName $settingName)) {
                Write-Verbose "Skipping '$settingName' - not created by Intune-Hydration-Kit"
                continue
            }

            if ($PSCmdlet.ShouldProcess($settingName, 'Delete W365 user settings')) {
                try {
                    Invoke-MgGraphRequest -Method DELETE -Uri "$endpoint/$($settingInfo.Id)" -ErrorAction Stop
                    Write-HydrationLog -Message "  Deleted: $settingName" -Level Info
                    $results += New-HydrationResult -Name $settingName -Type $resourceType -Action 'Deleted' -Status 'Success'
                }
                catch {
                    $errMessage = Get-GraphErrorMessage -ErrorRecord $_
                    Write-HydrationLog -Message "  Failed: $settingName - $errMessage" -Level Warning
                    $results += New-HydrationResult -Name $settingName -Type $resourceType -Action 'Failed' -Status "Delete failed: $errMessage"
                }
            }
            else {
                Write-HydrationLog -Message "  WouldDelete: $settingName" -Level Info
                $results += New-HydrationResult -Name $settingName -Type $resourceType -Action 'WouldDelete' -Status 'DryRun'
            }
        }
        return $results
    }

    # Load template
    if (-not (Test-Path $TemplatePath)) {
        Write-Warning "W365 user settings template not found: $TemplatePath"
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
    if ($existingSettings.ContainsKey($displayName)) {
        Write-HydrationLog -Message "  Skipped: $displayName" -Level Info
        $results += New-HydrationResult -Name $displayName -Path $TemplatePath -Type $resourceType -Action 'Skipped' -Status 'Already exists'
        return $results
    }

    $importBody = Copy-DeepObject -InputObject $template
    Remove-ReadOnlyGraphProperties -InputObject $importBody

    # Add hydration kit marker to description
    $existingDesc = if ($importBody.description) { $importBody.description } else { "" }
    $importBody.description = if ($existingDesc) { "$existingDesc - Imported by Intune-Hydration-Kit" } else { "Imported by Intune-Hydration-Kit" }

    # Create user settings
    if ($PSCmdlet.ShouldProcess($displayName, 'Create W365 user settings')) {
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
