terraform {
  backend "s3" {
    bucket         = "tehseen-ai-deployguard"
    key            = "dev/deployguard/infra.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}