<p align="center">
  <a href="https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/powershellgallery/v/EguibarIT.HousekeepingPS.svg"></a>
  <a href="https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/powershellgallery/vpre/EguibarIT.HousekeepingPS.svg?label=powershell%20gallery%20preview&colorB=yellow"></a>
  <a href="https://github.com/vreguibar/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/github/license/vreguibar/EguibarIT.HousekeepingPS.svg"></a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/powershellgallery/p/EguibarIT.HousekeepingPS.svg"></a>
  <a href="https://github.com/vreguibar/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/github/languages/top/vreguibar/EguibarIT.HousekeepingPS.svg"></a>
  <a href="https://github.com/vreguibar/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/github/languages/code-size/vreguibar/EguibarIT.HousekeepingPS.svg"></a>
  <a href="https://www.powershellgallery.com/packages/EguibarIT.HousekeepingPS"><img src="https://img.shields.io/powershellgallery/dt/EguibarIT.HousekeepingPS.svg"></a>
</p>

<p align="center">
  <a href="https://www.linkedin.com/in/VicenteRodriguezEguibar"><img src="https://img.shields.io/badge/LinkedIn-VicenteRodriguezEguibar-0077B5.svg?logo=LinkedIn"></a>
</p>

[!(https://img.shields.io/badge/Gitpod-ready--to--code-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/gitpod-io/workspace-images)

# EguibarIT.HousekeepingPS - Simplifying Active Directory Maintenance

## Overview

The "EguibarIT.HousekeepingPS" module is a powerful toolkit for AD administrators looking to automate the cleanup and maintenance of their Active Directory environments. It offers a range of functions to remove stale objects, generate detailed reports, and ensure administrators are informed through logs and email notifications. This module not only helps in keeping the AD environment clean but also aids in improving security and performance by ensuring only active and necessary objects remain in the directory.

## Key Features

- Automated Cleanup: The module provides tools to automate the cleanup of inactive AD objects, helping to maintain a tidy and efficient directory.
- Customizable: Parameters can be customized to fit specific organizational needs, such as specifying the age threshold for inactive objects.
- Reporting and Logging: Detailed reports and logs are generated to keep track of actions taken, which is crucial for auditing and compliance purposes.
- Email Notifications: Administrators are kept in the loop with email notifications, which can be configured to send summaries of housekeeping activities.

The AD Delegation Model (also known as [Role Based Access Control](http://eguibarit.eu/microsoft/active-directory/role-based-access-control/), or simply [RBAC](http://eguibarit.eu/microsoft/active-directory/role-based-access-control/)) is the implementation of: [Least Privileged Access](http://eguibarit.eu/least-privileged-access/), [Segregation of Duties](http://eguibarit.eu/segregation-of-duties/) and “[0 (zero) Admin](http://eguibarit.eu/0-admin-model/)“. By identifying the tasks that execute against Active Directory, we can categorize and organize in a set of functional groups, or roles. Those roles can be dynamically assigned to the [Semi-Privileged accounts](http://eguibarit.eu/privileged-semi-privileged-users/). This reduces the exposed rights by having what needs, and does provides an easy but effective auditing of rights. The model does helps reduce the running costs by increasing efficiency. Additionally increases the overall security of the directory, adhering to industry best practices.

The goal is to determine the effective performance of computer management. Designing a directory that supports an efficient and simple organic functionality of the company. Anyone can “transfer” the organigram of the company to AD, but often, will not provide any extra management benefit. Even worse, it may complicate it. Not to talk about security or [segregation of duties and assets](http://eguibarit.eu/segregation-of-duties/). Eguibar Information Technology S.L. can design the Active Directory based on the actual needs of the company focusing on computer management model. This benefits of the processes necessary for the daily management,  being more efficient, reducing maintenance costs and providing a high degree of security.
