function Test-IntunePrerequisites {
    <#
    .SYNOPSIS
        Validates Intune tenant prerequisites
    .DESCRIPTION
        Checks for Intune license availability and required Microsoft Graph permission scopes
    .EXAMPLE
        Test-IntunePrerequisites
    #>
    [CmdletBinding()]
    param()

    Write-Host "Validating Intune prerequisites..."

    $issues = @()

    # Required scopes from Connect-IntuneHydration
    $requiredScopes = @(
        "DeviceManagementConfiguration.ReadWrite.All",
        "DeviceManagementServiceConfig.ReadWrite.All",
        "DeviceManagementManagedDevices.ReadWrite.All",
        "DeviceManagementScripts.ReadWrite.All",
        "DeviceManagementApps.ReadWrite.All",
        "Group.ReadWrite.All",
        "Policy.Read.All",
        "Policy.ReadWrite.ConditionalAccess",
        "Application.Read.All",
        "Directory.ReadWrite.All"
    )

    try {
        # Check organization info and licenses
        $org = Invoke-MgGraphRequest -Method GET -Uri "beta/organization" -ErrorAction Stop
        $orgDetails = $org.value[0]

        Write-Host "Connected to: $($orgDetails.displayName)"

        # Check for Intune service plan
        $subscribedSkus = Invoke-MgGraphRequest -Method GET -Uri "beta/subscribedSkus" -ErrorAction Stop

        $intuneServicePlans = @(
            'INTUNE_A',           # Intune Plan 1
            'INTUNE_EDU',         # Intune for Education
            'INTUNE_SMBIZ',       # Intune Small Business
            'AAD_PREMIUM',        # Azure AD Premium (includes some Intune features)
            'EMSPREMIUM'          # Enterprise Mobility + Security
        )

        $hasIntune = $false
        foreach ($sku in $subscribedSkus.value) {
            foreach ($plan in $sku.servicePlans) {
                if ($plan.servicePlanName -in $intuneServicePlans -and $plan.provisioningStatus -eq 'Success') {
                    $hasIntune = $true
                    Write-Host "Found Intune license: $($plan.servicePlanName)"
                    break
                }
            }
            if ($hasIntune) { break }
        }

        if (-not $hasIntune) {
            $issues += "No active Intune license found. Please ensure Intune is licensed for this tenant."
        }

        # Check for required permission scopes
        $context = Get-MgContext
        if ($null -eq $context) {
            $issues += "Not connected to Microsoft Graph. Please run Connect-IntuneHydration first."
        } else {
            $currentScopes = $context.Scopes
            $missingScopes = @()

            foreach ($scope in $requiredScopes) {
                if ($currentScopes -notcontains $scope) {
                    $missingScopes += $scope
                }
            }

            if ($missingScopes.Count -gt 0) {
                $issues += "Missing required permission scopes: $($missingScopes -join ', ')"
                Write-Warning "Missing scopes detected. Please reconnect using Connect-IntuneHydration."
            } else {
                Write-Host "All required permission scopes are present"
            }
        }

        # Report results
        if ($issues.Count -gt 0) {
            foreach ($issue in $issues) {
                Write-Warning $issue
            }
            throw "Prerequisite checks failed. Please resolve the issues above before continuing."
        }

        Write-Host "All prerequisite checks passed"
        return $true
    }
    catch {
        if ($_.Exception.Message -match "Prerequisite checks failed") {
            throw
        }
        Write-Error "Failed to validate prerequisites: $_"
        throw
    }
}