# EguibarIT.HousekeepingPS - Simplifying Active Directory Maintenance

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/EguibarIT.HousekeepingPS.svg)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)
[![PowerShell Gallery Preview Version](https://img.shields.io/powershellgallery/vpre/EguibarIT.HousekeepingPS.svg?label=powershell%20gallery%20preview&colorB=yellow)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)
[![GitHub License](https://img.shields.io/github/license/vreguibar/EguibarIT.HousekeepingPS.svg)](https://github.com/vreguibar/EguibarIT.HousekeepingPS)

[![PowerShell Gallery](https://img.shields.io/powershellgallery/p/EguibarIT.HousekeepingPS.svg)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)
[![GitHub Top Language](https://img.shields.io/github/languages/top/vreguibar/EguibarIT.HousekeepingPS.svg)](https://github.com/vreguibar/EguibarIT.HousekeepingPS)
[![GitHub Code Size](https://img.shields.io/github/languages/code-size/vreguibar/EguibarIT.HousekeepingPS.svg)](https://github.com/vreguibar/EguibarIT.HousekeepingPS)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/EguibarIT.HousekeepingPS.svg)](https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-VicenteRodriguezEguibar-0077B5.svg?logo=LinkedIn)](https://www.linkedin.com/in/VicenteRodriguezEguibar)

The EguibarIT.HousekeepingPS PowerShell module is designed to assist in the maintenance and management of Active Directory (AD) environments. It provides a set of functions aimed at automating routine housekeeping tasks, improving security, and ensuring the overall health and compliance of AD objects. Here is a comprehensive description of the module's functionalities:

## Overview

The "EguibarIT.HousekeepingPS" module is a powerful toolkit for AD administrators looking to automate the cleanup and maintenance of their Active Directory environments. It offers a range of functions to remove stale objects, generate detailed reports, and ensure administrators are informed through logs and email notifications. This module not only helps in keeping the AD environment clean but also aids in improving security and performance by ensuring only active and necessary objects remain in the directory.

## Key Features

- Automated Cleanup: The module provides tools to automate the cleanup of inactive AD objects, helping to maintain a tidy and efficient directory.
- Customizable: Parameters can be customized to fit specific organizational needs, such as specifying the age threshold for inactive objects.
- Reporting and Logging: Detailed reports and logs are generated to keep track of actions taken, which is crucial for auditing and compliance purposes.
- Email Notifications: Administrators are kept in the loop with email notifications, which can be configured to send summaries of housekeeping activities.

1. Inactive Accounts Management

- Disable-InactiveUsers: Identifies and disables user accounts that have been inactive for a specified period.
- Remove-InactiveComputers: Deletes computer accounts that have not logged in for a defined duration.

1. Stale Objects Cleanup

- Remove-StaleObjects: Scans for and removes objects that have not been modified within a certain timeframe, reducing clutter and - potential security risks.

1.Security Enhancements

- Enforce-PasswordPolicies: Applies custom password policies to ensure all user accounts comply with organizational security standards.
- Audit-GroupMemberships: Audits group memberships to ensure that only authorized users are members of sensitive AD groups.

1. Compliance and Reporting

- Generate-ComplianceReport: Creates detailed reports on compliance with internal and external policies, helping organizations prepare for audits.
- Export-ADData: Exports AD data to CSV or other formats for further analysis and reporting.

1. Automation and Scheduling

- Schedule-HousekeepingTasks: Enables the scheduling of regular housekeeping tasks using Task Scheduler or other automation tools, ensuring continuous maintenance without manual intervention.

1. Logging and Monitoring

- Enable-ADLogging: Configures detailed logging of AD activities to help monitor changes and detect potential issues.
- Monitor-ADHealth: Provides real-time monitoring of AD health, including replication status and domain controller performance.
