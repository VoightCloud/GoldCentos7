# GoldCent7
# THIS README IS 100% OUT OF DATE. I HAVEN'T YET UPDATED IT FOR MY LOCAL DOMAIN AND PROXMOX SERVER

## Table of Contents 
<details>
<summary>Click to expand</summary>

- [Overview](#overview) 
- [Cattle Not Pets](#cattle-vs-pets) 
- [Usage](#usage)
    + [Jenkinsfile](#jenkins) 
    + [Terraform](#terraform) 
    + [Ansible Tower](#ansible-tower) 
    + [Nessus](#nessus)
- [Implementation](#implementation) 
    + [Overlays](#overlays) 
    + [jpetstore](#jpetstore)
    
</details>

## Overview

GoldCent 7 is a Gold Image pipeline for CentOS 7. It results in an 
AWS AMI that is hardened, secured, and pre-approved for use by 
development and deployment teams. To reduce the vulnerability footprint, 
it contains a minimal set of software required to run, for instance sshd, 
firewalld, subscription-manager, katello, McAfee Antivirus, Splunk 
forwarder, Tanium, and a few other necessary agents.

The image has been through the RedHat STIG process, has SeLinux enforcing,
firewalld enabled, but has disabled (or never enabled in the first place) 
katello, subscription-manager, Splunk forwarder. Those services are 
disabled so that the end user does not run into registration conflicts. 
For that reason, users of this Gold Image will need to enable those services 
at deploy time and re-register with subscription-manager. 

By using the latest Gold Image in your deployment, you take advantage of 
updates and security fixes that have already been approved for use on the 
network. Your development teams will no longer have to address 
operating system vulnerabilities that were not introduced by your team.

## Cattle vs. Pets

Using the Gold Image is not as simple as just standing up an instance,
applying your code, and forgetting about it. You also have to change your 
mindset about your deployments. Gone are the days of doing monthly or 
quarterly deployments and patching the infrastructure when issues arise.

Rather, you are expected to deploy **every day**, or even many times a day.

## Usage

### Jenkins

[Jenkins][jenkins-link] is used to automate the provisioning and 
scanning of the Gold CentOS 7 AMI. First, an instance is launched using
Terraform, then it is provisioned with Ansible Tower, finally it is 
scanned using Nessus. If the build is successful, a snapshot is taken of
the instance, and made available in AWS.

### Terraform

You will need a `dv` directory for your dev deployments. Eventually, 
you will need a `prod` directory for your production environment and 
directories for any other environments into which you deploy.

#### /template-ec2

This [launch template](./template-ec2/main.tf) is used to launch an 
EC2 instance using the "Grey" CentOS 7 AMI, which is simply an AMI that 
was created from the base CentOS 7.5 ISO using Packer (for more info, see
the [GreyCent7 repository][greycent7-link]).

Also in this template, [Ansible local](ansible/initialize.yaml) is used
to install some basic software, add ansible and nessus users, scan the
image with OpenSCAP, and finally STIG the image. 

#### /dv 

Inside the `dv` (deployment environment) directory, you will need a
`main.tf` and an `output.tf` file.

The [main.tf](dv/main.tf) will define the backend store and the node 
description. 

### Ansible Tower

In the Ansible Tower stage of the Jenkins build, we call various 
Ansible playbooks to provision the Gold AMI. 

#### dependencies 

1. [connection_test][connection_test-link]: tests Ansible connection
1. [required_software][required_software-link]: installs various agents
   and software, including Encase, Katello, McAfee, Nessus, Splunk, and
   Tanium  
    ** Note: this will **install** but only **register** Katello, all 
   other agents will not be registered 
1. [scapscan][scapscan-link]: runs a compliance scan against the instance
   using [OpenSCAP][openscap-link]
1. [unregister][unregister-link]: unregisters from katello and other 
   agents 

### Nessus

The Nessus API is used to run a scan against the instance. See the 
`launchNessusScan` function at the bottom of the [Jenkinsfile](./Jenkinsfile).
The report will be accessible in Nessus, but will also be archived
as a build artifact in Jenkins.

## Implementation

The Jenkins build results in the creation of an "Au-Cent7" AMI, 
which can be used by teams to deploy applications.

### Overlays

The [Gold Tomcat Overlay repo][overlay_tomcat-link] provides an
example of Terraform code that instantiates a Gold Cent7 image.
The result of the Tomcat Overlay Jenkins build is a pre-scanned, 
pre-STIG'd CentOS 7 AMI with Tomcat pre-installed and configured.
This AMI is ready to be used by application teams who would 
like to use Tomcat to deploy their applications. 

### jpetstore 

[JPetStore][jpetstore-link] is an example application used to 
demonstrate end-to-end use of the Gold CentOS 7 AMI. The Jenkins
build uses Terraform to instantiate an instance using the *latest*
"Au-Tomcat" AMI and then deploy JPetStore. 

[openscap-link]: <https://www.open-scap.org/>
