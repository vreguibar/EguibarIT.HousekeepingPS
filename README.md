# EguibarIT.HousekeepingPS - Simplifying Active Directory Maintenance

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/EguibarIT.HousekeepingPS.svg)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)
[![PowerShell Gallery Preview Version](https://img.shields.io/powershellgallery/vpre/EguibarIT.HousekeepingPS.svg?label=powershell%20gallery%20preview&colorB=yellow)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)
![GitHub Release](https://img.shields.io/github/v/release/vreguibar/EguibarIT.HousekeepingPS)
[![GitHub License](https://img.shields.io/github/license/vreguibar/EguibarIT.HousekeepingPS.svg)](https://github.com/vreguibar/EguibarIT.HousekeepingPS)

[![PowerShell Gallery](https://img.shields.io/powershellgallery/p/EguibarIT.HousekeepingPS.svg)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)
![GitHub language count](https://img.shields.io/github/languages/count/vreguibar/EguibarIT.HousekeepingPS)
[![GitHub Top Language](https://img.shields.io/github/languages/top/vreguibar/EguibarIT.HousekeepingPS.svg)](https://github.com/vreguibar/EguibarIT.HousekeepingPS)
[![GitHub Code Size](https://img.shields.io/github/languages/code-size/vreguibar/EguibarIT.HousekeepingPS.svg)](https://github.com/vreguibar/EguibarIT.HousekeepingPS)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/EguibarIT.HousekeepingPS.svg)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)

![GitHub Sponsors](https://img.shields.io/github/sponsors/vreguibar)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-VicenteRodriguezEguibar-0077B5.svg?logo=LinkedIn)](https://www.linkedin.com/in/VicenteRodriguezEguibar)

The EguibarIT.HousekeepingPS PowerShell module is designed to assist in the maintenance and management of Active Directory (AD) environments. It provides a set of functions aimed at automating routine housekeeping tasks, improving security, and ensuring the overall health and compliance of AD objects. Here is a comprehensive description of the module's functionalities:

## Overview

The "EguibarIT.HousekeepingPS" module is a powerful toolkit for AD administrators looking to automate the cleanup and maintenance of their Active Directory environments. It offers a range of functions to remove stale objects, generate detailed reports, and ensure administrators are informed through logs and email notifications. This module not only helps in keeping the AD environment clean but also aids in improving security and performance by ensuring only active and necessary objects remain in the directory.

## Key Features

### Inactive Accounts Management

- **Disable-InactiveUsers**: Identifies and disables user accounts that have been inactive for a specified period.
- **Remove-InactiveComputers**: Deletes computer accounts that have not logged in for a defined duration.

### Stale Objects Cleanup

- **Remove-StaleObjects**: Scans for and removes objects that have not been modified within a certain timeframe, reducing clutter and potential security risks.

### Security Enhancements

- **Enforce-PasswordPolicies**: Applies custom password policies to ensure all user accounts comply with organizational security standards.
- **Audit-GroupMemberships**: Audits group memberships to ensure that only authorized users are members of sensitive AD groups.

### Compliance and Reporting

- **Generate-ComplianceReport**: Creates detailed reports on compliance with internal and external policies, helping organizations prepare for audits.
- **Export-ADData**: Exports AD data to CSV or other formats for further analysis and reporting.

### Automation and Scheduling

- **Schedule-HousekeepingTasks**: Enables the scheduling of regular housekeeping tasks using Task Scheduler or other automation tools, ensuring continuous maintenance without manual intervention.

### Logging and Monitoring

- **Enable-ADLogging**: Configures detailed logging of AD activities to help monitor changes and detect potential issues.
- **Monitor-ADHealth**: Provides real-time monitoring of AD health, including replication status and domain controller performance.

## Example Use Cases

- **Routine Maintenance**: Schedule daily or weekly tasks to disable inactive accounts and clean up stale objects.
- **Security Audits**: Regularly audit group memberships and enforce password policies to maintain a secure AD environment.
- **Compliance Reporting**: Generate compliance reports periodically to ensure readiness for internal and external audits.

## Usage

Here is a brief example of how you might use the module to disable inactive users and generate a compliance report:

```powershell
# Import the module
Import-Module EguibarIT.HousekeepingPS

# Disable users inactive for more than 90 days
Disable-InactiveUsers -DaysInactive 90 -WhatIf

To install the EguibarIT.HousekeepingPS module, you can download it from the PowerShellGallery (or Github by cloning) and import it into your PowerShell session:

Find-Module EguibarIT.HousekeepingPS | InstallModule -Scope AllUsers -Force

Import-Module EguibarIT.HousekeepingPS
