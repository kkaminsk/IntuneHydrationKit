# Windows 365 Integration Proposal

## Application Specification for Windows 365 Provisioning & User Settings

**Version:** 1.0
**Status:** Proposed
**Target Module Version:** 0.2.0

---

## Executive Summary

This specification defines the requirements and implementation plan for extending the Intune Hydration Kit to support Windows 365 (Cloud PC) provisioning policies and user settings. This addition enables organizations to bootstrap their Windows 365 environment alongside existing Intune configurations.

---

## Scope

### In Scope

| Feature | Description |
|---------|-------------|
| Provisioning Policies | Create and manage Cloud PC provisioning configurations |
| User Settings | Configure user experience settings for Cloud PCs |
| Dynamic Groups | Create dynamic device groups targeting Cloud PCs |
| Compliance Policies | Cloud PC-specific compliance policies (separate from physical devices) |
| Configuration Profiles | Cloud PC-specific Windows configuration profiles |
| Gallery Image Selection | Reference Microsoft-provided OS images |
| Template-based Deployment | JSON templates following existing kit patterns |

### Out of Scope (Future Consideration)

| Feature | Rationale |
|---------|-----------|
| Custom Device Images | Requires Azure storage and image upload workflows |
| On-Premises Network Connections | Requires existing Azure AD/Entra hybrid infrastructure |
| License Assignment | Handled separately through M365 licensing |
| Frontline Worker Configurations | Specialized scenario requiring additional planning |

---

## Technical Requirements

### Prerequisites

#### Required Permissions

Add to `Connect-IntuneHydration.ps1` permission scopes:

```
CloudPC.ReadWrite.All
```

#### Windows 365 License Requirements

- Windows 365 Enterprise or Business licenses assigned to tenant
- Azure AD (Entra ID) joined or Hybrid joined device support

### Graph API Endpoints

| Resource | Endpoint | Method |
|----------|----------|--------|
| Provisioning Policies | `beta/deviceManagement/virtualEndpoint/provisioningPolicies` | GET, POST, DELETE |
| User Settings | `beta/deviceManagement/virtualEndpoint/userSettings` | GET, POST, PATCH, DELETE |
| Gallery Images | `beta/deviceManagement/virtualEndpoint/galleryImages` | GET |
| Service Plans | `beta/deviceManagement/virtualEndpoint/servicePlans` | GET |

---

## Implementation Design

### New Files

```
IntuneHydrationKit/
├── Public/
│   ├── Import-IntuneW365ProvisioningPolicy.ps1    # New
│   └── Import-IntuneW365UserSettings.ps1          # New
├── Templates/
│   ├── Compliance/
│   │   └── Windows365-Compliance-Policy.json      # Existing (update displayName/description)
│   ├── ConfigurationProfiles/
│   │   └── CloudPC-Configuration-Profile.json     # New
│   ├── DynamicGroups/
│   │   └── CloudPC-Groups.json                    # New
│   └── W365/
│       ├── ProvisioningPolicy.json                # Existing (populate with template)
│       └── UserSettings.json                      # Existing (populate with template)
```

### Modified Files

| File | Changes |
|------|---------|
| `IntuneHydrationKit.psd1` | Add new functions to `FunctionsToExport` |
| `Invoke-IntuneHydration.ps1` | Add orchestration steps for W365 imports |
| `settings.example.json` | Add `w365ProvisioningPolicies` and `w365UserSettings` flags |
| `Public/Connect-IntuneHydration.ps1` | Add `CloudPC.ReadWrite.All` scope |

---

## Function Specifications

### Import-IntuneW365ProvisioningPolicy

#### Synopsis

Imports Windows 365 provisioning policies from JSON templates.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TemplatePath` | String | No | Path to template file (defaults to `Templates/W365/ProvisioningPolicy.json`) |
| `RemoveExisting` | Switch | No | Remove existing hydration kit provisioning policies before import |

#### Behavior

1. Load provisioning policy templates from JSON files
2. Query existing policies via Graph API with pagination
3. Skip policies that already exist (by `displayName`)
4. Create new policies with hydration kit marker in description
5. Support `-WhatIf` for dry-run preview
6. Return standardized result objects

#### Graph API Schema (Provisioning Policy)

```json
{
  "displayName": "W365 Standard - Azure AD Join",
  "description": "Standard provisioning policy. Imported by Intune-Hydration-Kit",
  "provisioningType": "dedicated",
  "managedBy": "windows365",
  "imageId": "<gallery-image-id>",
  "imageType": "gallery",
  "windowsSettings": {
    "language": "en-US"
  },
  "domainJoinConfigurations": [
    {
      "type": "azureADJoin",
      "onPremisesConnectionId": null,
      "regionName": "automatic"
    }
  ],
  "microsoftManagedDesktop": {
    "type": "notManaged"
  },
  "enableSingleSignOn": true
}
```

#### Example Usage

```powershell
# Preview what would be created
Import-IntuneW365ProvisioningPolicy -WhatIf

# Import policies
Import-IntuneW365ProvisioningPolicy

# Remove and recreate
Import-IntuneW365ProvisioningPolicy -RemoveExisting
```

---

### Import-IntuneW365UserSettings

#### Synopsis

Imports Windows 365 user settings policies from JSON templates.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TemplatePath` | String | No | Path to template file (defaults to `Templates/W365/UserSettings.json`) |
| `RemoveExisting` | Switch | No | Remove existing hydration kit user settings before import |

#### Behavior

1. Load user settings templates from JSON files
2. Query existing user settings via Graph API with pagination
3. Skip settings that already exist (by `displayName`)
4. Create new settings with hydration kit marker in description
5. Support `-WhatIf` for dry-run preview
6. Return standardized result objects

#### Graph API Schema (User Settings)

```json
{
  "displayName": "W365 Standard User Settings",
  "description": "Standard user experience settings. Imported by Intune-Hydration-Kit",
  "localAdminEnabled": false,
  "selfServiceEnabled": true,
  "restorePointSetting": {
    "frequencyType": "sixHours",
    "userRestoreEnabled": true
  },
  "resetEnabled": true
}
```

#### Example Usage

```powershell
# Preview what would be created
Import-IntuneW365UserSettings -WhatIf

# Import user settings
Import-IntuneW365UserSettings

# Remove and recreate
Import-IntuneW365UserSettings -RemoveExisting
```

---

## Template Specifications

### Provisioning Policy Template

#### Templates/W365/ProvisioningPolicy.json

This existing file should be populated with the provisioning policy template. The file currently exists but is empty.

**Recommended Template Content:**

```json
{
  "displayName": "W365 Standard - Azure AD Join",
  "description": "Standard Cloud PC provisioning with Azure AD Join. Imported by Intune-Hydration-Kit",
  "provisioningType": "dedicated",
  "managedBy": "windows365",
  "imageType": "gallery",
  "imageDisplayName": "Windows 11 Enterprise + Microsoft 365 Apps 24H2",
  "windowsSettings": {
    "language": "en-US"
  },
  "domainJoinConfigurations": [
    {
      "type": "azureADJoin",
      "regionName": "automatic"
    }
  ],
  "enableSingleSignOn": true,
  "microsoftManagedDesktop": {
    "type": "notManaged"
  }
}
```

**Template Properties:**

| Property | Value | Description |
|----------|-------|-------------|
| `provisioningType` | `dedicated` | Each user gets their own Cloud PC |
| `managedBy` | `windows365` | Managed by Windows 365 service |
| `imageType` | `gallery` | Uses Microsoft-provided gallery image |
| `imageDisplayName` | `Windows 11 Enterprise + M365 Apps 24H2` | Resolved to `imageId` at runtime |
| `domainJoinConfigurations.type` | `azureADJoin` | Azure AD Join (Entra ID) |
| `regionName` | `automatic` | Azure selects optimal region |
| `enableSingleSignOn` | `true` | Enable SSO for Cloud PC access |

**Note:** For Hybrid Azure AD Join scenarios, modify `domainJoinConfigurations` to include `onPremisesConnectionId`.

### User Settings Template

#### Templates/W365/UserSettings.json

This existing file should be populated with the user settings template. The file currently exists but is empty.

**Recommended Template Content:**

```json
{
  "displayName": "W365 Standard User Settings",
  "description": "Standard user experience settings for Windows 365 Cloud PCs. Imported by Intune-Hydration-Kit",
  "localAdminEnabled": false,
  "selfServiceEnabled": true,
  "restorePointSetting": {
    "frequencyType": "sixHours",
    "userRestoreEnabled": true
  },
  "resetEnabled": true
}
```

**Template Properties:**

| Property | Value | Description |
|----------|-------|-------------|
| `localAdminEnabled` | `false` | Users are not local administrators |
| `selfServiceEnabled` | `true` | Users can access self-service portal |
| `restorePointSetting.frequencyType` | `sixHours` | Restore points created every 6 hours |
| `restorePointSetting.userRestoreEnabled` | `true` | Users can restore their Cloud PC |
| `resetEnabled` | `true` | Users can reset their Cloud PC |

**Alternative: Restricted Settings**

For regulated environments requiring tighter controls:

```json
{
  "displayName": "W365 Restricted User Settings",
  "description": "Restricted user settings for regulated environments. Imported by Intune-Hydration-Kit",
  "localAdminEnabled": false,
  "selfServiceEnabled": false,
  "restorePointSetting": {
    "frequencyType": "twelveHours",
    "userRestoreEnabled": false
  },
  "resetEnabled": false
}
```

---

## Cloud PC Policy Separation Rationale

Windows 365 Cloud PCs require separate compliance and configuration policies from physical Windows devices due to fundamental architectural differences:

### Why Separate Policies?

| Consideration | Physical Device | Cloud PC | Impact |
|---------------|-----------------|----------|--------|
| **TPM** | Hardware TPM 2.0 | Virtual TPM (vTPM) | Both support TPM compliance checks |
| **Secure Boot** | UEFI Secure Boot | Virtual Secure Boot | Cloud PCs support Secure Boot verification |
| **BitLocker** | User/policy-managed | Platform-managed by Azure | Cloud PC policy omits BitLocker requirement |
| **Disk Encryption** | Explicit policy required | Azure-managed at rest | No BitLocker policy needed for Cloud PCs |
| **Network Location** | Corporate/remote varies | Always Azure-connected | Different firewall/network considerations |
| **Hardware Compliance** | OEM-specific variations | Standardized virtual HW | Consistent hardware baseline |
| **Update Rings** | Complex ring strategy | Simplified via image updates | Different update management approach |
| **Code Integrity** | HVCI varies by hardware | Consistent HVCI support | Cloud PCs provide reliable HVCI |

### Policy Design Principles

1. **Leverage Virtual Security** - Cloud PCs support vTPM, Virtual Secure Boot, and HVCI consistently across all SKUs
2. **Skip BitLocker Requirement** - Azure manages disk encryption at the platform level; explicit BitLocker policy is unnecessary
3. **Consistent Compliance** - Cloud PC hardware is standardized, enabling stricter baseline requirements
4. **Independent Lifecycle** - Separate policies allow Cloud PC configurations to evolve independently from physical device policies

### Assignment Strategy

| Policy Type | Target Group | Exclusion |
|-------------|--------------|-----------|
| Physical Windows Compliance | `Intune - Windows 11 Devices` | `Intune - All Cloud PCs` |
| Cloud PC Compliance | `Intune - All Cloud PCs` | None |
| Physical Windows Config | `Intune - Windows 11 Devices` | `Intune - All Cloud PCs` |
| Cloud PC Config | `Intune - All Cloud PCs` | None |

---

## Cloud PC Compliance & Configuration Templates

### Compliance Policy Template

#### Templates/Compliance/Windows365-Compliance-Policy.json

This existing compliance policy template is used for Cloud PC devices. The `displayName` and `description` should be updated to clearly identify it as a Windows 365 policy.

**Recommended Updates to Existing File:**

| Field | Current Value | Recommended Value |
|-------|---------------|-------------------|
| `displayName` | `"Windows Compliance Policy"` | `"Windows 365 Cloud PC Compliance Policy"` |
| `description` | `"Windows Compliance Policy using GUI settings"` | `"Compliance policy for Windows 365 Cloud PCs. Imported by Intune-Hydration-Kit"` |

**Current Template Contents:**

```json
{
    "@odata.type": "#microsoft.graph.windows10CompliancePolicy",
    "displayName": "Windows 365 Cloud PC Compliance Policy",
    "description": "Compliance policy for Windows 365 Cloud PCs.",
    "roleScopeTagIds": ["0"],
    "activeFirewallRequired": true,
    "antiSpywareRequired": true,
    "antivirusRequired": true,
    "codeIntegrityEnabled": true,
    "defenderEnabled": true,
    "deviceThreatProtectionEnabled": false,
    "deviceThreatProtectionRequiredSecurityLevel": "unavailable",
    "passwordRequiredType": "deviceDefault",
    "rtpEnabled": true,
    "scheduledActionsForRule": [
        {
            "ruleName": "PasswordRequired",
            "scheduledActionConfigurations": [
                {
                    "actionType": "block",
                    "gracePeriodHours": 12,
                    "notificationMessageCCList": [],
                    "notificationTemplateId": ""
                },
                {
                    "actionType": "retire",
                    "gracePeriodHours": 4320,
                    "notificationMessageCCList": [],
                    "notificationTemplateId": ""
                }
            ]
        }
    ],
    "secureBootEnabled": true,
    "signatureOutOfDate": true,
    "tpmRequired": true
}
```

**Policy Settings Explained:**

| Setting | Value | Rationale |
|---------|-------|-----------|
| `activeFirewallRequired` | `true` | Windows Firewall must be enabled |
| `antiSpywareRequired` | `true` | Defender Antispyware required |
| `antivirusRequired` | `true` | Defender Antivirus required |
| `codeIntegrityEnabled` | `true` | Hypervisor-protected code integrity (HVCI) |
| `defenderEnabled` | `true` | Windows Defender must be active |
| `rtpEnabled` | `true` | Real-time protection enabled |
| `secureBootEnabled` | `true` | Virtual Secure Boot verification |
| `tpmRequired` | `true` | Virtual TPM (vTPM) required |
| `signatureOutOfDate` | `true` | Defender signatures must be current |

**Scheduled Actions:**
- **Block** after 12 hours of non-compliance
- **Retire** after 4320 hours (180 days) of non-compliance

**Note:** This template is processed by the existing `Import-IntuneCompliancePolicy` function. Assign to the `Intune - All Cloud PCs` dynamic group.

---

### Configuration Profile Template

#### Templates/ConfigurationProfiles/CloudPC-Configuration-Profile.json

This settings catalog profile contains Cloud PC-optimized Windows configurations.

```json
{
    "name": "Cloud PC Configuration Profile",
    "description": "Windows configuration profile optimized for Windows 365 Cloud PCs.",
    "platforms": "windows10",
    "technologies": "mdm",
    "roleScopeTagIds": ["0"],
    "settings": [
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                "settingDefinitionId": "device_vendor_msft_policy_config_experience_allowwindowsspotlight",
                "choiceSettingValue": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                    "value": "device_vendor_msft_policy_config_experience_allowwindowsspotlight_0"
                }
            }
        },
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                "settingDefinitionId": "device_vendor_msft_policy_config_experience_allowwindowsconsumerfeatures",
                "choiceSettingValue": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                    "value": "device_vendor_msft_policy_config_experience_allowwindowsconsumerfeatures_0"
                }
            }
        },
        {
            "@odata.type": "#microsoft.graph.deviceManagementConfigurationSetting",
            "settingInstance": {
                "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance",
                "settingDefinitionId": "device_vendor_msft_policy_config_privacy_disableadvertisingid",
                "choiceSettingValue": {
                    "@odata.type": "#microsoft.graph.deviceManagementConfigurationChoiceSettingValue",
                    "value": "device_vendor_msft_policy_config_privacy_disableadvertisingid_1"
                }
            }
        }
    ]
}
```

**Cloud PC-Specific Configuration Considerations:**

| Setting Category | Recommendation | Rationale |
|------------------|----------------|-----------|
| Windows Spotlight | Disable | Reduce distractions in virtual workspace |
| Consumer Features | Disable | Enterprise-focused experience |
| Advertising ID | Disable | Privacy in shared/pooled scenarios |
| OneDrive Known Folders | Enable | Critical for Cloud PC data persistence |
| Windows Update | Managed via Image | Reduce policy complexity |

**Note:** This template uses the Settings Catalog format and is processed by the existing `Import-IntuneConfigurationPolicy` function. Assign to the `Intune - All Cloud PCs` dynamic group.

---

### Dynamic Group Template

#### Templates/DynamicGroups/CloudPC-Groups.json

This template creates dynamic groups for targeting Cloud PC devices with policies and applications.

**Note:** This template is processed by the existing `New-IntuneDynamicGroup` function - no new import function is required. The template is added to the existing `Templates/DynamicGroups/` folder alongside other group templates.

```json
{
    "groups": [
        {
            "displayName": "Intune - All Cloud PCs",
            "description": "All Windows 365 Cloud PC devices managed by Intune",
            "membershipRule": "(device.deviceModel -eq \"Cloud PC\")"
        },
        {
            "displayName": "Intune - Cloud PCs Windows 11",
            "description": "All Windows 365 Cloud PC devices running Windows 11",
            "membershipRule": "(device.deviceModel -eq \"Cloud PC\") and (device.deviceOSVersion -startsWith \"10.0.2\")"
        }
    ]
}
```

**Membership Rule Notes:**
- Cloud PCs register with `deviceModel` = `"Cloud PC"` in Entra ID
- Can be combined with OS version filters for targeted deployments
- Groups auto-populate as Cloud PCs are provisioned

**Use Cases:**
| Group | Purpose |
|-------|---------|
| All Cloud PCs | Apply baseline security policies, compliance policies |
| Cloud PCs Windows 11 | Target OS-specific configurations, feature updates |

---

## Configuration Schema Updates

### settings.example.json

Add to the `imports` section:

```json
{
  "imports": {
    "complianceTemplates": true,
    "configurationPolicies": true,
    "conditionalAccessPolicies": true,
    "w365ProvisioningPolicies": true,
    "w365UserSettings": true
  },
  "w365": {
    "galleryImageName": "Windows 11 Enterprise + Microsoft 365 Apps 24H2",
    "onPremisesConnectionId": null,
    "defaultRegion": "automatic"
  }
}
```

---

## Implementation Pseudocode

### Import-IntuneW365ProvisioningPolicy.ps1

```powershell
function Import-IntuneW365ProvisioningPolicy {
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

    # Handle RemoveExisting
    if ($RemoveExisting) {
        $existingPolicies = Get-AllGraphObjects -Endpoint $endpoint
        foreach ($policy in $existingPolicies) {
            if (Test-HydrationKitObject -Description $policy.description -ObjectName $policy.displayName) {
                if ($PSCmdlet.ShouldProcess($policy.displayName, 'Delete')) {
                    try {
                        Invoke-MgGraphRequest -Method DELETE -Uri "$endpoint/$($policy.id)"
                        $results += New-HydrationResult -Name $policy.displayName -Type $resourceType -Action 'Deleted' -Status 'Success'
                    }
                    catch {
                        $results += New-HydrationResult -Name $policy.displayName -Type $resourceType -Action 'Failed' -Status (Get-GraphErrorMessage $_)
                    }
                }
                else {
                    $results += New-HydrationResult -Name $policy.displayName -Type $resourceType -Action 'WouldDelete' -Status 'DryRun'
                }
            }
        }
        return $results
    }

    # Load template
    if (-not (Test-Path $TemplatePath)) {
        Write-HydrationLog -Message "W365 provisioning policy template not found: $TemplatePath" -Level Warning
        return $results
    }

    $template = Get-Content -Path $TemplatePath -Raw -Encoding utf8 | ConvertFrom-Json

    # Get existing policies for comparison
    $existingPolicies = Get-AllGraphObjects -Endpoint $endpoint

    # Resolve gallery image ID if needed
    $galleryImages = Invoke-MgGraphRequest -Method GET -Uri 'beta/deviceManagement/virtualEndpoint/galleryImages'

    # Process template
    $displayName = $template.displayName

    # Check if already exists
    $existing = $existingPolicies | Where-Object { $_.displayName -eq $displayName }
    if ($existing) {
        Write-HydrationLog -Message "Skipping '$displayName' - already exists" -Level Info
        $results += New-HydrationResult -Name $displayName -Type $resourceType -Action 'Skipped' -Status 'Already exists'
        return $results
    }

    # Resolve gallery image by display name
    if ($template.imageDisplayName -and $template.imageType -eq 'gallery') {
        $matchingImage = $galleryImages.value | Where-Object { $_.displayName -like "*$($template.imageDisplayName)*" } | Select-Object -First 1
        if ($matchingImage) {
            $template | Add-Member -NotePropertyName 'imageId' -NotePropertyValue $matchingImage.id -Force
        }
        $template.PSObject.Properties.Remove('imageDisplayName')
    }

    # Add hydration kit marker if not already present
    if ($template.description -and $template.description -notlike '*Intune-Hydration-Kit*') {
        $template.description = "$($template.description) Imported by Intune-Hydration-Kit"
    }
    elseif (-not $template.description) {
        $template | Add-Member -NotePropertyName 'description' -NotePropertyValue 'Imported by Intune-Hydration-Kit'
    }

    # Create policy
    if ($PSCmdlet.ShouldProcess($displayName, 'Create')) {
        try {
            $body = $template | Remove-ReadOnlyGraphProperties | ConvertTo-Json -Depth 10
            Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body $body -ErrorAction Stop
            $results += New-HydrationResult -Name $displayName -Type $resourceType -Action 'Created' -Status 'Success'
            Write-HydrationLog -Message "Created provisioning policy '$displayName'" -Level Success
        }
        catch {
            $errorMessage = Get-GraphErrorMessage $_
            $results += New-HydrationResult -Name $displayName -Type $resourceType -Action 'Failed' -Status $errorMessage
            Write-HydrationLog -Message "Failed to create '$displayName': $errorMessage" -Level Error
        }
    }
    else {
        $results += New-HydrationResult -Name $displayName -Type $resourceType -Action 'WouldCreate' -Status 'DryRun'
    }

    return $results
}
```

---

## Testing Plan

### Unit Tests

| Test Case | Description |
|-----------|-------------|
| Template Loading | Verify JSON templates load and parse correctly |
| Existing Policy Skip | Confirm duplicate policies are skipped |
| WhatIf Mode | Validate no changes made during dry run |
| Remove Existing | Confirm only hydration kit objects are deleted |
| Error Handling | Verify graceful failure on API errors |

### Integration Tests

| Test Case | Description |
|-----------|-------------|
| End-to-End Create | Create policies in test tenant |
| Idempotency | Run import twice, verify no duplicates |
| Permission Validation | Confirm CloudPC.ReadWrite.All scope works |
| Gallery Image Resolution | Verify image name-to-ID mapping |

### Manual Validation

1. Run `Invoke-IntuneHydration.ps1 -WhatIf` with W365 templates
2. Verify policies appear in Windows 365 admin center
3. Confirm description contains hydration kit marker
4. Test `-RemoveExisting` only removes kit-created policies

---

## Rollout Considerations

### Breaking Changes

None. This is an additive feature.

### Migration Path

Existing users can opt-in by:
1. Adding `w365ProvisioningPolicies: true` to settings
2. Adding `w365UserSettings: true` to settings

### Documentation Updates

| Document | Updates Needed |
|----------|----------------|
| README.md | Add W365 section with prerequisites |
| CLAUDE.md | Add W365 endpoints to table |
| settings.example.json | Include W365 configuration options |

---

## Open Questions

1. **Hybrid Join Support** - Should templates include placeholders for `onPremisesConnectionId`, or should this be a separate parameter?

2. **Gallery Image Selection** - Should the kit automatically select the latest Windows 11 image, or require explicit specification?

3. **Assignment Groups** - Should provisioning policies include group assignments, or leave this to manual configuration?

4. **Frontline Workers** - Should shared/kiosk provisioning types be included in initial release?

5. **Policy Assignments** - Should the kit automatically assign Cloud PC compliance/configuration policies to the `Intune - All Cloud PCs` group, or leave assignment to the administrator?

6. **Physical Device Exclusions** - Should the kit automatically add the `Intune - All Cloud PCs` group as an exclusion to existing physical Windows device policies to prevent conflicts?

7. **Compliance Policy Strictness** - Should Cloud PC compliance include multiple tiers (Basic, Standard, Strict) similar to physical device policies?

---

## Appendix A: Graph API Reference

### Provisioning Policy Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `displayName` | String | Yes | Policy name |
| `description` | String | No | Policy description |
| `provisioningType` | Enum | Yes | `dedicated` or `shared` |
| `imageType` | Enum | Yes | `gallery` or `custom` |
| `imageId` | String | Yes | Gallery or custom image ID |
| `domainJoinConfigurations` | Array | Yes | Join configuration objects |
| `windowsSettings` | Object | No | Language and regional settings |
| `enableSingleSignOn` | Boolean | No | Enable SSO for Cloud PC |

### User Settings Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `displayName` | String | Yes | Settings name |
| `description` | String | No | Settings description |
| `localAdminEnabled` | Boolean | No | Allow local admin |
| `selfServiceEnabled` | Boolean | No | Enable self-service portal |
| `restorePointSetting` | Object | No | Restore point configuration |
| `resetEnabled` | Boolean | No | Allow user-initiated reset |

---

## Appendix B: Required Permission Scopes

### Current Scopes (Connect-IntuneHydration.ps1)

```
DeviceManagementConfiguration.ReadWrite.All
DeviceManagementApps.ReadWrite.All
DeviceManagementManagedDevices.ReadWrite.All
Policy.ReadWrite.ConditionalAccess
Group.ReadWrite.All
```

### Additional Scope for W365

```
CloudPC.ReadWrite.All
```

---

## Appendix C: Error Handling Matrix

| Error Code | Cause | Resolution |
|------------|-------|------------|
| 403 | Missing CloudPC.ReadWrite.All | Re-run Connect-IntuneHydration |
| 404 | W365 not provisioned in tenant | Verify Windows 365 license |
| 400 | Invalid gallery image ID | Check image availability in region |
| 409 | Duplicate policy name | Skip or use -RemoveExisting |

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-30 | Proposed | Initial specification |
