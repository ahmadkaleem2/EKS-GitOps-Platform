variable "albc_values" {
    type        = map(string)
    description = "A map of key-value pairs to set on the ALBC."
    default = {

    }
}

variable "namespace" {
    type        = string
    description = "The namespace to install the ALBC into."
    default     = "aws-load-balancer-controller"
  
}