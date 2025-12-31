## Why

The Intune Hydration Kit currently provisions physical device configurations but lacks support for Windows 365 Cloud PCs. Organizations deploying both physical devices and Cloud PCs need a unified bootstrapping solution that provisions Windows 365 provisioning policies, user settings, and Cloud PC-specific compliance configurations.

## What Changes

- **New Functions**: Add `Import-IntuneW365ProvisioningPolicy` and `Import-IntuneW365UserSettings` to create Windows 365 configurations
- **Permission Scope**: Add `CloudPC.ReadWrite.All` to `Connect-IntuneHydration.ps1`
- **Templates**: Populate existing `Templates/W365/` JSON templates for provisioning policies and user settings
- **Dynamic Groups**: Add Cloud PC targeting groups (`Intune - All Cloud PCs`)
- **Configuration Profile**: Add Cloud PC-specific configuration profile template
- **Orchestrator Integration**: Update `Invoke-IntuneHydration.ps1` to include W365 import steps
- **Settings Schema**: Add `w365ProvisioningPolicies` and `w365UserSettings` flags to settings

## Impact

- Affected specs: `w365-provisioning` (new capability)
- Affected code:
  - `Public/Import-IntuneW365ProvisioningPolicy.ps1` (new)
  - `Public/Import-IntuneW365UserSettings.ps1` (new)
  - `Public/Connect-IntuneHydration.ps1` (add scope)
  - `IntuneHydrationKit.psd1` (export functions)
  - `Invoke-IntuneHydration.ps1` (orchestration)
  - `settings.example.json` (add flags)
  - `Templates/W365/ProvisioningPolicy.json` (populate)
  - `Templates/W365/UserSettings.json` (populate)
  - `Templates/DynamicGroups/CloudPC-Groups.json` (new)
  - `Templates/ConfigurationProfiles/CloudPC-Configuration-Profile.json` (new)
