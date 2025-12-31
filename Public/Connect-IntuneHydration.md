# Connect-IntuneHydration

## Synopsis

Connects to Microsoft Graph with required scopes for Intune hydration.

## Description

Establishes authentication to Microsoft Graph using interactive, client secret, or certificate-based authentication. Supports multiple cloud environments including Global (Commercial), US Government, US Government DoD, Germany, and China.

Certificate authentication is the recommended method for automation scenarios as it provides stronger security than client secrets.

## Syntax

### Interactive Authentication
```powershell
Connect-IntuneHydration
    -TenantId <String>
    [-Interactive]
    [-Environment <String>]
```

### Client Secret Authentication
```powershell
Connect-IntuneHydration
    -TenantId <String>
    -ClientId <String>
    -ClientSecret <SecureString>
    [-Environment <String>]
```

### Certificate Thumbprint Authentication
```powershell
Connect-IntuneHydration
    -TenantId <String>
    -ClientId <String>
    -CertificateThumbprint <String>
    [-Environment <String>]
```

### Certificate Subject Authentication
```powershell
Connect-IntuneHydration
    -TenantId <String>
    -ClientId <String>
    -CertificateSubject <String>
    [-Environment <String>]
```

## Parameters

### -TenantId

The Azure AD tenant ID (GUID or domain name like `contoso.onmicrosoft.com`).

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |

### -ClientId

Application (client) ID for app registration authentication.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes (for app auth) |

### -ClientSecret

Client secret for authentication. Use SecureString for production environments.

| Attribute | Value |
|-----------|-------|
| Type | SecureString |
| Required | Yes (for ClientSecret auth) |

### -CertificateThumbprint

Thumbprint of the certificate to use for authentication. Certificate must be in `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My`.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes (for Thumbprint auth) |

### -CertificateSubject

Subject name of the certificate (e.g., `CN=Intune-Hydration-Kit`). Uses the most recent valid certificate with matching subject.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes (for Subject auth) |

### -Interactive

Use interactive (browser-based) authentication.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

### -Environment

Graph environment to connect to.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Global` |
| Valid Values | `Global`, `USGov`, `USGovDoD`, `Germany`, `China` |

## Required Permission Scopes

The following Graph API scopes are requested:

| Scope | Purpose |
|-------|---------|
| `DeviceManagementConfiguration.ReadWrite.All` | Configuration policies |
| `DeviceManagementServiceConfig.ReadWrite.All` | Service configuration |
| `DeviceManagementManagedDevices.ReadWrite.All` | Device management |
| `DeviceManagementScripts.ReadWrite.All` | PowerShell scripts |
| `DeviceManagementApps.ReadWrite.All` | App management |
| `Group.ReadWrite.All` | Dynamic groups |
| `Policy.Read.All` | Policy read access |
| `Policy.ReadWrite.ConditionalAccess` | Conditional Access policies |
| `Application.Read.All` | Application read |
| `Directory.ReadWrite.All` | Directory write access |

## Cloud Environments

| Environment | Graph Endpoint |
|-------------|---------------|
| Global | `https://graph.microsoft.com` |
| USGov | `https://graph.microsoft.us` |
| USGovDoD | `https://dod-graph.microsoft.us` |
| Germany | `https://graph.microsoft.de` |
| China | `https://microsoftgraph.chinacloudapi.cn` |

## Examples

### Example 1: Interactive authentication

```powershell
Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" -Interactive
```

Opens a browser for interactive sign-in.

### Example 2: Client secret authentication

```powershell
$secret = Read-Host -AsSecureString -Prompt "Client Secret"
Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" `
    -ClientId "12345678-1234-1234-1234-123456789012" `
    -ClientSecret $secret
```

### Example 3: Certificate authentication with thumbprint

```powershell
Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" `
    -ClientId "12345678-1234-1234-1234-123456789012" `
    -CertificateThumbprint "ABC123DEF456..."
```

### Example 4: Certificate authentication with subject

```powershell
Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" `
    -ClientId "12345678-1234-1234-1234-123456789012" `
    -CertificateSubject "CN=Intune-Hydration-Kit"
```

### Example 5: US Government cloud

```powershell
Connect-IntuneHydration -TenantId "contoso.onmicrosoft.us" `
    -Interactive `
    -Environment USGov
```

## Script State Variables

After successful connection, these script-level variables are set:

| Variable | Description |
|----------|-------------|
| `$script:HydrationState.Connected` | `$true` when connected |
| `$script:HydrationState.TenantId` | Connected tenant GUID |
| `$script:HydrationState.Environment` | Cloud environment name |
| `$script:HydrationState.AuthMode` | Authentication method used |
| `$script:GraphEnvironment` | Environment name |
| `$script:GraphEndpoint` | Graph API base URL |

## Security Recommendations

1. **Prefer certificate authentication** for automation scenarios
2. **Use SecureString** for client secrets, never plain text
3. **Limit app permissions** to only what's required
4. **Review consent** for interactive authentication

## Related Functions

- [Test-IntunePrerequisites](Test-IntunePrerequisites.md)
- [Import-HydrationSettings](Import-HydrationSettings.md)
