## Objectives
To design and construct an Amazon Virtual Private Cloud (VPC) architecture that includes an EC2 instance within a public subnet and a database instance within a private subnet

Problem Statement and Motivation

Real-Time Scenario:

James, a systems engineer at a startup company, is tasked with developing a web application with a secure, robust, and scalable backend database.

The company plans to utilize AWS RDS for the database, while the application will be deployed on an EC2 instance.

James must ensure a secure VPC setup where the EC2 instance resides in the public subnet and the RDS DB instance in a private subnet.

Problem Statement and Motivation

Expected Solution:

As a cloud architect, your objective is to assist James in developing an AWS VPC that hosts both an EC2 instance and a database instance.

The EC2 instance, serving the web application, should be placed in a public subnet, while the DB instance should be secured in a private subnet.

You are expected to provide step-by-step instructions for creating and configuring these AWS resources, ensuring system security, reliability, and accessibility.


## Solution
![Image](https://github.com/huyphamch/terraform-aws-create-web-rds/blob/master/manual/Project1.drawio.png)
<br />My solution is to create a VPC with two Amazon EC2 instances in different availability zones and separate public subnets in a region. 
Then the RDS database supporting multi availability zones is created in a private subnet to only allow data access from the EC2 instances within the security group.
Http requests a forwarded from the Internet Gateway to the EC2 instances which can access the data from the RDS database and send the response via Internet Gateway to the client.

<br />The manual steps to achieve the same result using the AWS management console are documented [here](https://github.com/huyphamch/terraform-aws-create-web-rds/blob/master/manual/Project1.pdf)

## Prerequisites
<br /> You have access to AWS services, for example via Free tier AWS account.
<br /> AWS CLI and Terraform are already installed.

## Usage
<br /> 1. Open terminal
<br /> 2. Before you can execute the terraform script, your need to configure your aws environment first.
<br /> aws configure
<br /> AWS Access Key ID: See IAM > Security credentials > Access keys > Create access key
<br /> AWS Secret Access Key: See IAM > Security credentials > Access keys > Create access key
<br /> Default region name: us-east-1
<br /> Default output format: json
<br /> 3. Now you can apply the terraform changes.
<br /> terraform init
<br /> terraform apply --auto-approve
<br /> Result: Calling the URL from the web browser should display the static web page
<br /> 4. At the end you can cleanup the created AWS resources.
<br /> terraform destroy --auto-approve
