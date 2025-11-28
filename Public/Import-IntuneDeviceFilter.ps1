function Import-IntuneDeviceFilter {
    <#
    .SYNOPSIS
        Creates device filters for Intune
    .DESCRIPTION
        Creates device filters by manufacturer for each device OS platform (Windows, macOS, iOS/iPadOS, Android).
        Creates 3 manufacturer filters per OS: Dell/HP/Lenovo for Windows, Apple for macOS/iOS.
    .EXAMPLE
        Import-IntuneDeviceFilter
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$RemoveExisting
    )

    $results = @()

    # Get all existing filters first with pagination (OData filter on displayName not supported for this endpoint)
    # Store full filter objects so we can check descriptions later
    $existingFilters = @{}
    try {
        $listUri = "beta/deviceManagement/assignmentFilters?`$select=id,displayName,description"
        do {
            $existingFiltersResponse = Invoke-MgGraphRequest -Method GET -Uri $listUri -ErrorAction Stop
            foreach ($existingFilter in $existingFiltersResponse.value) {
                if (-not $existingFilters.ContainsKey($existingFilter.displayName)) {
                    $existingFilters[$existingFilter.displayName] = @{
                        Id = $existingFilter.id
                        Description = $existingFilter.description
                    }
                }
            }
            $listUri = $existingFiltersResponse.'@odata.nextLink'
        } while ($listUri)
    }
    catch {
        Write-Warning "Could not retrieve existing filters: $_"
        $existingFilters = @{}
    }

    # Build a simple name->id lookup for backwards compatibility in the import section
    $existingFilterNames = @{}
    foreach ($key in $existingFilters.Keys) {
        $existingFilterNames[$key] = $existingFilters[$key].Id
    }

    # Define filters first so we know what to delete
    $filterDefinitions = @(
        # Windows filters by manufacturer
        @{
            DisplayName = "Windows - Dell Devices"
            Description = "Filter for Dell Windows devices"
            Platform = "windows10AndLater"
            Rule = '(device.manufacturer -eq "Dell Inc.")'
        },
        @{
            DisplayName = "Windows - HP Devices"
            Description = "Filter for HP Windows devices"
            Platform = "windows10AndLater"
            Rule = '(device.manufacturer -eq "HP") or (device.manufacturer -eq "Hewlett-Packard")'
        },
        @{
            DisplayName = "Windows - Lenovo Devices"
            Description = "Filter for Lenovo Windows devices"
            Platform = "windows10AndLater"
            Rule = '(device.manufacturer -eq "LENOVO")'
        },
        # macOS filters
        @{
            DisplayName = "macOS - Apple Devices"
            Description = "Filter for Apple macOS devices"
            Platform = "macOS"
            Rule = '(device.manufacturer -eq "Apple")'
        },
        @{
            DisplayName = "macOS - MacBook Devices"
            Description = "Filter for MacBook devices"
            Platform = "macOS"
            Rule = '(device.model -startsWith "MacBook")'
        },
        @{
            DisplayName = "macOS - iMac Devices"
            Description = "Filter for iMac devices"
            Platform = "macOS"
            Rule = '(device.model -startsWith "iMac")'
        },
        # iOS/iPadOS filters
        @{
            DisplayName = "iOS - iPhone Devices"
            Description = "Filter for iPhone devices"
            Platform = "iOS"
            Rule = '(device.model -startsWith "iPhone")'
        },
        @{
            DisplayName = "iOS - iPad Devices"
            Description = "Filter for iPad devices"
            Platform = "iOS"
            Rule = '(device.model -startsWith "iPad")'
        },
        @{
            DisplayName = "iOS - Corporate Owned"
            Description = "Filter for corporate-owned iOS/iPadOS devices"
            Platform = "iOS"
            Rule = '(device.deviceOwnership -eq "Corporate")'
        },
        # Android filters
        @{
            DisplayName = "Android - Samsung Devices"
            Description = "Filter for Samsung Android devices"
            Platform = "androidForWork"
            Rule = '(device.manufacturer -eq "samsung")'
        },
        @{
            DisplayName = "Android - Google Pixel Devices"
            Description = "Filter for Google Pixel devices"
            Platform = "androidForWork"
            Rule = '(device.manufacturer -eq "Google")'
        },
        @{
            DisplayName = "Android - Corporate Owned"
            Description = "Filter for corporate-owned Android devices"
            Platform = "androidForWork"
            Rule = '(device.deviceOwnership -eq "Corporate")'
        }
    )

    # Remove existing filters if requested
    # SAFETY: Only delete filters that have "Imported by Intune-Hydration-Kit" in description
    if ($RemoveExisting) {
        foreach ($filterName in $existingFilters.Keys) {
            $filterInfo = $existingFilters[$filterName]

            # Safety check: Only delete if created by this kit (has hydration marker in description)
            if (-not (Test-HydrationKitObject -Description $filterInfo.Description -ObjectName $filterName)) {
                Write-Verbose "Skipping '$filterName' - not created by Intune-Hydration-Kit"
                continue
            }

            if ($PSCmdlet.ShouldProcess($filterName, "Delete device filter")) {
                try {
                    Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/assignmentFilters/$($filterInfo.Id)" -ErrorAction Stop
                    Write-HydrationLog -Message "  Deleted: $filterName" -Level Info
                    $results += New-HydrationResult -Name $filterName -Type 'DeviceFilter' -Action 'Deleted' -Status 'Success'
                }
                catch {
                    $errMessage = Get-GraphErrorMessage -ErrorRecord $_
                    Write-HydrationLog -Message "  Failed: $filterName - $errMessage" -Level Warning
                    $results += New-HydrationResult -Name $filterName -Type 'DeviceFilter' -Action 'Failed' -Status "Delete failed: $errMessage"
                }
            }
            else {
                Write-HydrationLog -Message "  WouldDelete: $filterName" -Level Info
                $results += New-HydrationResult -Name $filterName -Type 'DeviceFilter' -Action 'WouldDelete' -Status 'DryRun'
            }
        }

        return $results
    }

    foreach ($filter in $filterDefinitions) {
        try {
            # Check if filter already exists using pre-fetched list
            if ($existingFilterNames.ContainsKey($filter.DisplayName)) {
                Write-HydrationLog -Message "  Skipped: $($filter.DisplayName)" -Level Info
                $results += New-HydrationResult -Name $filter.DisplayName -Id $existingFilterNames[$filter.DisplayName] -Platform $filter.Platform -Action 'Skipped' -Status 'Already exists'
                continue
            }

            if ($PSCmdlet.ShouldProcess($filter.DisplayName, "Create device filter")) {
                $filterBody = @{
                    displayName = $filter.DisplayName
                    description = "$($filter.Description) - Imported by Intune-Hydration-Kit"
                    platform = $filter.Platform
                    rule = $filter.Rule
                    roleScopeTags = @("0")
                }

                $newFilter = Invoke-MgGraphRequest -Method POST -Uri "beta/deviceManagement/assignmentFilters" -Body $filterBody -ErrorAction Stop

                Write-HydrationLog -Message "  Created: $($filter.DisplayName)" -Level Info

                $results += New-HydrationResult -Name $filter.DisplayName -Id $newFilter.id -Platform $filter.Platform -Action 'Created' -Status 'Success'
            }
            else {
                Write-HydrationLog -Message "  WouldCreate: $($filter.DisplayName)" -Level Info
                $results += New-HydrationResult -Name $filter.DisplayName -Platform $filter.Platform -Action 'WouldCreate' -Status 'DryRun'
            }
        }
        catch {
            Write-HydrationLog -Message "  Failed: $($filter.DisplayName) - $_" -Level Warning
            $results += New-HydrationResult -Name $filter.DisplayName -Platform $filter.Platform -Action 'Failed' -Status $_.Exception.Message
        }
    }

    return $results
}
