terraform {
  required_version = ">= 1.10.5" # Ou a versão que você definiu no env do workflow

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Ajuste conforme sua necessidade
    }
  }
}