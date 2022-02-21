#aws instance creation
resource "aws_instance" "os1" {
  ami           = "instance-image-id"
  instance_type = "t2.micro"
  security_groups =  [ "secret-group-name" ]
   key_name = "key-name-used-to-create-instance"
  tags = {
    Name = "TerraformOS"
  }
}#ebs volume created
resource "aws_ebs_volume" "ebs"{
  availability_zone =  aws_instance.os1.availability_zone
  size              = 1
  tags = {
    Name = "myterraebs"
  }
}#ebs volume attatched to instance
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs.id
  instance_id = aws_instance.os1.id
  force_detach = true
}

#IP of aws instance copied to a file ip.txt in local system
resource "local_file" "ip" {
    content  = aws_instance.os1.public_ip
    filename = "ip.txt"
}#connecting to the Ansible control node using SSH connection
resource "null_resource" "nullremote1" {
depends_on = [aws_instance.os1]
connection {
 type     = "ssh"
 user     = "root"
 password = "${var.password}"
     host= "${var.host}"
}#copying the ip.txt file to the Ansible control node from local system
provisioner "file" {
    source      = "ip.txt"
    destination = "/root/ansible_terraform/aws_instance/ip.txt"
       }
}

#connecting to the Linux OS having the Ansible playbook
resource "null_resource" "nullremote2" {
depends_on = [aws_volume_attachment.ebs_att]
connection {
	type     = "ssh"
	user     = "root"
	password = "${var.password}"
    	host= "${var.host}"
}
#command to run ansible playbook on remote Linux OS
provisioner "remote-exec" {

    inline = [
	"cd /root/ansible_terraform/aws_instance/",
	"ansible-playbook instance.yml"
]
}
}


# to automatically open the webpage on local system
resource "null_resource" "nullremote3" {
depends_on = [null_resource.nullremote2]
provisioner "local-exec" {
command = "chrome http://${aws_instance.os1.public_ip}/web/"
}
}
