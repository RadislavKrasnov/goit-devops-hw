terraform {
    backend "s3" {
        bucket         = "radyslav-lesson-5-tfstate-001001"
        key            = "lesson-5/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "terraform-locks"
        encrypt        = true
    }
}
