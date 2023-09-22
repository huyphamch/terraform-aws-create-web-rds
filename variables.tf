variable "subnet_cidr_public" {
  description = "cidr blocks for the public subnets"
  default     = ["10.20.20.0/28", "10.20.20.16/28"]
  type        = list(any)
}

variable "subnet_cidr_private" {
  description = "cidr blocks for the public subnets"
  default     = ["10.20.20.32/28", "10.20.20.48/28"]
  type        = list(any)
}

variable "availability_zone" {
  description = "availability zones for the public subnets"
  default     = ["us-east-1a", "us-east-1b"]
  type        = list(any)
}