## ADDED Requirements

### Requirement: Windows 365 Provisioning Policy Import

The system SHALL import Windows 365 provisioning policies from JSON templates via the `Import-IntuneW365ProvisioningPolicy` function using the Graph API endpoint `beta/deviceManagement/virtualEndpoint/provisioningPolicies`.

#### Scenario: Create provisioning policy from template

- **WHEN** the user runs `Import-IntuneW365ProvisioningPolicy` with a valid template
- **THEN** a provisioning policy is created in the tenant with the template settings and hydration kit marker in description

#### Scenario: Skip existing provisioning policy

- **WHEN** the user runs `Import-IntuneW365ProvisioningPolicy` and a policy with the same displayName already exists
- **THEN** the policy is skipped and a result with Action 'Skipped' and Status 'Already exists' is returned

#### Scenario: Remove existing provisioning policies

- **WHEN** the user runs `Import-IntuneW365ProvisioningPolicy -RemoveExisting`
- **THEN** only policies with "Imported by Intune-Hydration-Kit" in description are deleted

#### Scenario: Dry run with WhatIf

- **WHEN** the user runs `Import-IntuneW365ProvisioningPolicy -WhatIf`
- **THEN** no policies are created and results show Action 'WouldCreate'

### Requirement: Windows 365 User Settings Import

The system SHALL import Windows 365 user settings from JSON templates via the `Import-IntuneW365UserSettings` function using the Graph API endpoint `beta/deviceManagement/virtualEndpoint/userSettings`.

#### Scenario: Create user settings from template

- **WHEN** the user runs `Import-IntuneW365UserSettings` with a valid template
- **THEN** user settings are created in the tenant with the template settings and hydration kit marker in description

#### Scenario: Skip existing user settings

- **WHEN** the user runs `Import-IntuneW365UserSettings` and settings with the same displayName already exist
- **THEN** the settings are skipped and a result with Action 'Skipped' and Status 'Already exists' is returned

#### Scenario: Remove existing user settings

- **WHEN** the user runs `Import-IntuneW365UserSettings -RemoveExisting`
- **THEN** only settings with "Imported by Intune-Hydration-Kit" in description are deleted

#### Scenario: Dry run with WhatIf

- **WHEN** the user runs `Import-IntuneW365UserSettings -WhatIf`
- **THEN** no settings are created and results show Action 'WouldCreate'

### Requirement: Gallery Image Resolution

The system SHALL resolve gallery image display names to image IDs at runtime by querying the `beta/deviceManagement/virtualEndpoint/galleryImages` endpoint.

#### Scenario: Resolve image by display name

- **WHEN** a provisioning policy template contains `imageDisplayName` and `imageType` is 'gallery'
- **THEN** the system queries gallery images and sets `imageId` to the matching image's ID

#### Scenario: Image not found

- **WHEN** the specified `imageDisplayName` does not match any available gallery image
- **THEN** the import fails with a clear error message indicating the image was not found

### Requirement: CloudPC Permission Scope

The system SHALL include the `CloudPC.ReadWrite.All` permission scope in `Connect-IntuneHydration` to enable Windows 365 API access.

#### Scenario: Connect with CloudPC scope

- **WHEN** the user runs `Connect-IntuneHydration`
- **THEN** the `CloudPC.ReadWrite.All` scope is requested during authentication

### Requirement: Cloud PC Dynamic Groups

The system SHALL provide JSON templates for dynamic groups that target Cloud PC devices using the membership rule `(device.deviceModel -eq "Cloud PC")`.

#### Scenario: Create Cloud PC dynamic group

- **WHEN** the Cloud PC groups template is processed by `New-IntuneDynamicGroup`
- **THEN** dynamic groups are created with membership rules that filter Cloud PC devices

### Requirement: Orchestrator W365 Integration

The system SHALL include W365 provisioning policy and user settings import steps in `Invoke-IntuneHydration.ps1` when the corresponding flags are enabled in settings.

#### Scenario: Import W365 policies via orchestrator

- **WHEN** `Invoke-IntuneHydration.ps1` is run with `w365ProvisioningPolicies: true` in settings
- **THEN** `Import-IntuneW365ProvisioningPolicy` is called as part of the hydration process

#### Scenario: Import W365 user settings via orchestrator

- **WHEN** `Invoke-IntuneHydration.ps1` is run with `w365UserSettings: true` in settings
- **THEN** `Import-IntuneW365UserSettings` is called as part of the hydration process

#### Scenario: Skip W365 when disabled

- **WHEN** `Invoke-IntuneHydration.ps1` is run with W365 flags set to false or absent
- **THEN** W365 import functions are not called
