variable "project" {
  description = "Nome do projeto"
  type        = string
  default     = "technova-aula10"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI Ubuntu 22.04 LTS us-east-1"
  type        = string
  default     = "ami-0fc5d935ebf8bc3bc"
}

variable "key_name" {
  description = "Nome do key pair para SSH"
  type        = string
  default     = "technova-aula10-key"
}
