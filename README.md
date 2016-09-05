# Provision a Windows AMI using Packer

Sometimes it's quite challenging to find a standard way of installing software on a windows machine from the command line (at least for me as i'm used to `yum install` or `apt-get`, etc).

You could use [chocolatey](https://chocolatey.org/) but if for some reason you don't want to have any external dependencies or don't want to host your own chocolatey repo, you could use powershell to install the software in silent mode, that is what I have done and hope it can be help to resolve issues you might be experiencing or inspire you to create something more robust.


## Dependencies
 - Install [packer](http://packer.io)
 - There should be a default VPC in your AWS account, otherwise you have to indicate your vpc id which is also fine
 - Packer will authenticate to AWS using your exported AWS\* credentials or your ~/.aws/credentials file, do not set any credentials in files that are checked in your code repository.

## Usage
There is a variables section on top of the script that is used to define default variables:

```
"variables": {
  "base_ami_id": ""
}
```

If default values are present, they can be overridden from the command line, this is how you provision a new AMI from the command line using packer:

```
packer build -var "base_ami_id=ami-47bf8b24" provision-windows.json
```
