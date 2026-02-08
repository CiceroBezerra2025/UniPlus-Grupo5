variable "db_username" {
  description = "Usuário mestre do banco de dados RDS"
  type        = string
  default     = "admin" # Você pode alterar o padrão aqui
}

variable "db_password" {
  description = "Senha do banco de dados RDS"
  type        = string
  sensitive   = true # Isso evita que a senha apareça nos logs do console
}