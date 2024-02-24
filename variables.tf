variable "identifier" {
  description = "Unique identifier to differentiate global resources"
  type        = string
  validation {
    condition     = length(var.identifier) > 2
    error_message = "Identifier must be at least 3 characters"
  }
}

variable "name" {
  description = "Name of this module which is used as identifier on all resources"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domain pointed to the CloudFront distribution"
  type        = string
}

variable "zone_id" {
  description = "ID of the domain's Route53 public hosted zone"
  type        = string
}

variable "price_class" {
  description = "Price class for the CloudFront distribution"
  type        = string
  default     = "PriceClass_All"
  validation {
    condition     = var.price_class == "PriceClass_All" || var.price_class == "PriceClass_200" || var.price_class == "PriceClass_100"
    error_message = "Price class must be one of these values: 'PriceClass_All', 'PriceClass_200', 'PriceClass_100'"
  }
}

variable "min_ttl" {
  description = "Minimum amount of time (in seconds) that you want objects to stay in CloudFront caches before CloudFront queries the origin to see whether the object has been updated"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default amount of time (in seconds) that an object is in a CloudFront cache before CloudFront forwards another request in the absence of an 'Cache-Control max-age' or 'Expires' header"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum amount of time (in seconds) that an object is in a CloudFront cache before CloudFront forwards another request to your origin to determine whether the object has been updated"
  type        = number
  default     = 86400
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = !contains(keys(var.tags), "Name")
    error_message = "Name tag is reserved and will be used automatically"
  }
}
