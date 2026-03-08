variable "app_password" {
  description = "Application database password"
  type        = string
  default     = "AppUserPassword123!"
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/FernandoFdezdC/prueba_tecnica_globant.git"
}

variable "app_host" {
  description = "Application host"
  type        = string
  default     = "0.0.0.0"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8000
}

variable "mysql_password" {
  description = "MySQL master password"
  type        = string
  sensitive   = true

}