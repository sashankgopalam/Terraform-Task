provider "aws"{
    region = "us-east-1"
}
module "code"{
     source="/home/ec2-user/Task-2/Modules"
}
