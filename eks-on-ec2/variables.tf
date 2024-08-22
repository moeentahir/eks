
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "rancher-eks-cluster"
}

variable "rancher_api_url" {
  description = "Rancher API URL"
  type        = string
}

variable "rancher_access_key" {
  description = "Rancher access key"
  type        = string
}

variable "rancher_secret_key" {
  description = "Rancher secret key"
  type        = string
  sensitive   = true
}

variable "rancher_insecure" {
  description = "Disable Rancher SSL certificate validation"
  type        = bool
  default     = false
}
