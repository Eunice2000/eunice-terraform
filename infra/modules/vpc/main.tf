# Data source declaration for all necessary fetch
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

output "aws_default_vpc" {
  value = data.aws_vpc.default_vpc.id
}

output "aws_subnets" {
  value = data.aws_subnets.subnets.id
}