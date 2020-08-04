variable "location" {
  description = "The Azure region in which to create all resources."
  default = "West US"
}

variable "environment" {
  description = "Name of environment"
  default = "staging"
}

variable "serviceName" {
  description = "Name of storage"
  default = "billing"
}

variable "sas_token_startdate" {
  description = "Start date for SAS token"
  default = "2020-08-01T00:00:00Z"
}