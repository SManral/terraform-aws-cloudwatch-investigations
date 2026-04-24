variable "product" {}

variable "tags" {
  type = map(string)
}

variable "cw_investigation_notifications" {
  type = map(string)
}
