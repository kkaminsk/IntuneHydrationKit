## Context

This change adds Windows 365 Cloud PC provisioning support to the Intune Hydration Kit. The implementation follows existing patterns established by other import functions (e.g., `Import-IntuneCompliancePolicy`).

**Stakeholders**: IT administrators deploying Windows 365 alongside physical Windows devices.

**Constraints**:
- Must use beta Graph API endpoints (Windows 365 APIs are in beta)
- Gallery image IDs vary by region; resolution by display name required
- Provisioning policies cannot be updated in-place; require delete/recreate

## Goals / Non-Goals

**Goals**:
- Provision Windows 365 provisioning policies via JSON templates
- Provision Windows 365 user settings via JSON templates
- Support Azure AD Join configurations (Entra ID)
- Enable Cloud PC-specific compliance and configuration policies
- Maintain consistency with existing kit patterns (WhatIf, hydration markers, result tracking)

**Non-Goals**:
- Custom device image upload (requires Azure storage workflows)
- Hybrid Azure AD Join support (requires on-premises network connections)
- Frontline/shared provisioning types (specialized scenario)
- Automatic policy assignments (left to administrator)

## Decisions

### Decision: Use gallery image display name resolution

The `imageId` property in provisioning policies is a GUID that varies by region and time. Instead of hardcoding IDs, templates use `imageDisplayName` which is resolved at runtime by querying the gallery images endpoint.

**Alternatives considered**:
- Hardcode image ID: Rejected - IDs change and vary by region
- Require user to specify ID: Rejected - poor UX, error-prone

### Decision: Separate compliance policies for Cloud PCs

Cloud PCs have architectural differences from physical devices (vTPM, Azure-managed encryption) that make shared policies problematic. A dedicated compliance policy template (`Windows365-Compliance-Policy.json`) targets the `Intune - All Cloud PCs` dynamic group.

**Alternatives considered**:
- Shared compliance policy: Rejected - BitLocker requirements break on Cloud PCs
- Conditional exclusions: Rejected - more complex to manage

### Decision: Follow existing import function patterns

New W365 import functions follow the established pattern:
- `[CmdletBinding(SupportsShouldProcess)]` for WhatIf support
- `TemplatePath` and `RemoveExisting` parameters
- Pagination handling for existing object queries
- `Test-HydrationKitObject` for safe deletions
- `New-HydrationResult` for result tracking

**Rationale**: Consistency reduces learning curve and maintenance burden.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Beta API changes | Monitor Graph API changelog; use versioned endpoints |
| Gallery image not found | Clear error message with available images list |
| Missing CloudPC.ReadWrite.All scope | Pre-flight check in import functions |

## Migration Plan

This is an additive feature with no breaking changes.

**Opt-in activation**:
1. Add `w365ProvisioningPolicies: true` to settings.json
2. Add `w365UserSettings: true` to settings.json
3. Re-run `Connect-IntuneHydration` to pick up new scope

**Rollback**: Set flags to `false` or remove from settings.

## Open Questions

1. Should templates include multiple provisioning policy variants (Standard, Secure)?
2. Should the kit auto-assign policies to the Cloud PC dynamic group?
3. Should physical device policies auto-exclude the Cloud PC group?
