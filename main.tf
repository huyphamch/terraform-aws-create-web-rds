# Creation Dependencie:
# VPC - Subnet+IGW - RT
# VPC - Subnet+EIP - NGW - RT
# VPC - Subnet+SG - EC2
# AccessKey - EC2
# VPC - Subnet+SG+DBSubnetGroup - RDS

# 1. Create VPC
resource "aws_vpc" "vpc-load-balancer" {
  cidr_block = "10.0.0.0/26"
  enable_dns_hostnames = "true"
  tags = {
      Name = "vpc-load-balancer"
  }
}

# 2. Create Subnet
resource "aws_subnet" "subnet-public" {
  vpc_id = aws_vpc.vpc-load-balancer.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.0.0/27"
  map_public_ip_on_launch = true
  tags = {
        Name = "subnet-public"
  }
}

resource "aws_subnet" "subnet-private" {
  vpc_id = aws_vpc.vpc-load-balancer.id
  availability_zone = "us-east-1a"
  cidr_block = "10.0.0.32/28"
  map_public_ip_on_launch = false
  tags = {
      Name = "subnet-private"
  }
}

resource "aws_subnet" "subnet-private2" {
  vpc_id = aws_vpc.vpc-load-balancer.id
  availability_zone = "us-east-1b"
  cidr_block = "10.0.0.48/28"
  map_public_ip_on_launch = false
  tags = {
      Name = "subnet-private2"
  }
}

# 3. Create Internet-Gateway
resource "aws_internet_gateway" "igw-web"{
  vpc_id = aws_vpc.vpc-load-balancer.id
  tags = {
      Name = "igw-web"
  }
}

# 4. Create Elastic IP
resource "aws_eip" "elastic-ip-nat-gateway" {
  domain = "vpc"
  
  tags = {
    Name = "elastic-ip-nat-gateway"
  }
}

resource "aws_eip" "elastic-ip-nat-gateway2" {
  domain = "vpc"
  
  tags = {
    Name = "elastic-ip-nat-gateway2"
  }
}

# 5. Create NAT-Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic-ip-nat-gateway.id
  subnet_id = aws_subnet.subnet-private.id
  depends_on = [ aws_nat_gateway.nat_gateway ]
}

resource "aws_nat_gateway" "nat_gateway2" {
  allocation_id = aws_eip.elastic-ip-nat-gateway2.id
  subnet_id = aws_subnet.subnet-private2.id
  depends_on = [ aws_nat_gateway.nat_gateway2 ]
}

# 6. Create Route-Table
resource "aws_route_table" "rt-public"{
  vpc_id = aws_vpc.vpc-load-balancer.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw-web.id
  }
  tags = {
      Name = "rt-public"
  }
}

resource "aws_route_table" "rt-private"{
  vpc_id = aws_vpc.vpc-load-balancer.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
      Name = "rt-private"
  }
}

resource "aws_route_table" "rt-private2"{
  vpc_id = aws_vpc.vpc-load-balancer.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.nat_gateway2.id
  }
  tags = {
      Name = "rt-private2"
  }
}

# 7. Assign subnet to route table
resource "aws_route_table_association" "rta-public"{
  subnet_id = aws_subnet.subnet-public.id
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_route_table_association" "rta-private"{
  subnet_id = aws_subnet.subnet-private.id
  route_table_id = aws_route_table.rt-private.id
}

# 8. Create security group to allow port: Http, Https, SSH, RDP
resource "aws_security_group" "security-group-web" {
  name        = "Allow_inbound_traffic"
  description = "Allow https, http, ssh inbound traffic"
  vpc_id      = aws_vpc.vpc-load-balancer.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group-web"
  }
}

resource "aws_security_group" "security-group-database" {
  name        = "Allow_inbound_traffic_database"
  description = "Allow mysql inbound traffic to database"
  vpc_id      = aws_vpc.vpc-load-balancer.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [ aws_security_group.security-group-web.id ]   # Keep the instance private by only allowing traffic from the web server.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group-database"
  }
}

# 9.a Create Amazon Linux-Apache2 EC2-instance
resource "aws_instance" "web-linux" {
  ami = "ami-03a6eaae9938c858c"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair.key_name
  availability_zone = "us-east-1a"
  subnet_id     = aws_subnet.subnet-public.id
  vpc_security_group_ids =  [ aws_security_group.security-group-web.id ]

  user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd.x86_64
sudo yum install git -y
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
EOF

  tags = {
    Name = "web-linux"
  }
}

# 9.b Create Windows-IIS EC2-instance
resource "aws_instance" "web-windows" {
  ami = "ami-0be0e902919675894"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair.key_name
  availability_zone = "us-east-1a"
  subnet_id     = aws_subnet.subnet-public.id
  vpc_security_group_ids =  [ aws_security_group.security-group-web.id ]

  user_data = <<-EOF
<powershell>
Install-WindowsFeature -name Web-Server -IncludeManagementTools
New-Item -Path C:\inetpub\wwwroot\index.html -ItemType File -Value "Hello World Page" -Force
</powershell>
EOF

  tags = {
    Name = "web-windows"
  }
}

# 10. Create a RDS Database Instance
resource "aws_db_subnet_group" "db-subnet-group-mysql" {
  name = "db-subnet-group-mysql"
  subnet_ids = [ aws_subnet.subnet-private.id, aws_subnet.subnet-private2.id ]
}

/* 
* allocated_storage: This is the amount in GB
* storage_type: Type of storage we want to allocate(options avilable "standard" (magnetic), "gp2" (general purpose SSD), or "io1" (provisioned IOPS SSD)
* engine: Database engine(for supported values check https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html) eg: Oracle, Amazon Aurora,Postgres 
* engine_version: engine version to use
* instance_class: instance type for rds instance
* name: The name of the database to create when the DB instance is created.
* username: Username for the master DB user.
* password: Password for the master DB user
* db_subnet_group_name:  DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC
* vpc_security_group_ids: List of VPC security groups to associate.
* allows_major_version_upgrade: Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible.
* auto_minor_version_upgrade:Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Defaults to true.
* backup_retention_period: The days to retain backups for. Must be between 0 and 35. When creating a Read Replica the value must be greater than 0
* backup_window: The daily time range (in UTC) during which automated backups are created if they are enabled. Must not overlap with maintenance_window
* maintainence_window: The window to perform maintenance in. Syntax: "ddd:hh24:mi-ddd:hh24:mi".
* multi_az: Specifies if the RDS instance is multi-AZ
* skip_final_snapshot: Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier. Default is false
 */
resource "aws_db_instance" "db-mysql" {
  identifier           = "db-mysql-instance"
  allocated_storage    =  20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.33"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "admnin123"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group-mysql.name
  vpc_security_group_ids = [ aws_security_group.security-group-database.id ]
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 35
  backup_window               = "22:00-23:00"
  maintenance_window          = "Sat:00:00-Sat:03:00"
  multi_az                    = true  
  skip_final_snapshot  = true
  publicly_accessible =  true
}
