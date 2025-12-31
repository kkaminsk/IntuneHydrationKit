## 1. Permission and Authentication

- [x] 1.1 Add `CloudPC.ReadWrite.All` scope to `Connect-IntuneHydration.ps1` scopes array

## 2. Template Files

- [x] 2.1 Populate `Templates/W365/ProvisioningPolicy.json` with Azure AD Join provisioning template
- [x] 2.2 Populate `Templates/W365/UserSettings.json` with standard user settings template
- [x] 2.3 Create `Templates/DynamicGroups/CloudPC-Groups.json` with Cloud PC dynamic group definitions
- [x] 2.4 Create `Templates/ConfigurationProfiles/CloudPC-Configuration-Profile.json` with settings catalog profile

## 3. Import Functions

- [x] 3.1 Create `Public/Import-IntuneW365ProvisioningPolicy.ps1` following existing import patterns
  - Include TemplatePath and RemoveExisting parameters
  - Implement gallery image resolution by display name
  - Add hydration kit marker to description
  - Support -WhatIf for dry-run preview
- [x] 3.2 Create `Public/Import-IntuneW365UserSettings.ps1` following existing import patterns
  - Include TemplatePath and RemoveExisting parameters
  - Add hydration kit marker to description
  - Support -WhatIf for dry-run preview

## 4. Module Registration

- [x] 4.1 Add `Import-IntuneW365ProvisioningPolicy` to FunctionsToExport in `IntuneHydrationKit.psd1`
- [x] 4.2 Add `Import-IntuneW365UserSettings` to FunctionsToExport in `IntuneHydrationKit.psd1`

## 5. Orchestrator Integration

- [x] 5.1 Add W365 provisioning policy import step to `Invoke-IntuneHydration.ps1`
- [x] 5.2 Add W365 user settings import step to `Invoke-IntuneHydration.ps1`
- [x] 5.3 Update `settings.example.json` with `w365ProvisioningPolicies` and `w365UserSettings` flags

## 6. Documentation

- [x] 6.1 Update CLAUDE.md with W365 Graph API endpoints table
- [x] 6.2 Add W365 prerequisites section to README.md
