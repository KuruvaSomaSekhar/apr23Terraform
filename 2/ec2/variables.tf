variable "InstanceType" {
  type        = string
  default     = "t3.micro"

}

variable "AMIID" {
  type        = string
  default     = "ami-06a0cd9728546d178"
}

variable "icount" {
  type        = number
}
