variable "region" {
  type = string
  default = "us-east-1"
}

variable "environment" {
  type = string
  description = "Deployment Environment"
}

variable "vpc_name" {
  type = string
  description = "The name of the vpc"
}

variable "service_name" {
  type = string
  description = "The name of the service deployed with the ELB"
}

variable "key_name" {
  type = string
  description = "Name of the key pair created in AWS"
}