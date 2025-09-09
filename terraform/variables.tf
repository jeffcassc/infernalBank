variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "inferno-bank"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}