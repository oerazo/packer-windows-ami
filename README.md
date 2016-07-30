# Provision a Windows AMI using Packer

Sometimes it's quite challenging to find a standard way of installing software on a windows machine from the command line (at least for me as i'm used to `yum install` or `apt-get`, etc).

You could use [chocolatey](https://chocolatey.org/) but if for some reason you don't want to have any external dependencies or don't want to host your own chocolatey repo, you could use powershell to install the software in silent mode, that is what I have done and hope it can be help to resolve issues you might be experiencing or inspire you to create something more robust.


## Dependencies
 - Install [packer](http://packer.io)
 - There should be a VPC in your AWS account
 - Packer will authenticate to AWS using your exported AWS\* credentials or your ~/.aws/credentials file, do not set any credentials in files that are checked in your code repository.

## Usage
There is a variables section inside the script that is used to define default variables:

```
"variables": {
  "admin_password": "",
  "base_ami_id": ""
}
```
If default values are present , they can be changed from the command line, this is how you provision a new AMI from the command line using packer:

```
packer build -var "base_ami_id=ami-6c14310f" -var "admin_password=fairpass" provision-ami.json
```

The admin_password variable is only used as an example in case you have your own policies around passwords and want to set your own, the packer script has a step to change the password at the very end.
