resource "aws_instance" "shn_pa_connector" {
  instance_type               = "t3.xlarge"
  ami                         = data.aws_ami.ubuntu-linux-2204.id
  key_name                    = aws_key_pair.key_pair.key_name
  #vpc_security_group_ids      = [aws_security_group.appgate-sg.id]
  vpc_security_group_ids      = [aws_security_group.sselab-sg.id]
  associate_public_ip_address = var.linux_associate_public_ip_address
  #subnet_id                   = aws_subnet.public-subnet.id
  subnet_id                   = aws_subnet.public-subnet2.id
  #associate_public_ip_address = true

  root_block_device {
    volume_size = 100
  }

#  provisioner "file" {
#    source      = "~/PrivateAccess"
#    destination = "/home/ubuntu"
#  }

#  provisioner "remote-exec" {
#    inline = [
#      "chmod +x /home/ubuntu/PrivateAccess/poppackage.sh",
#      "/home/ubuntu/PrivateAccess/poppackage.sh",
#    ]
#  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/shnkey")
  }

  provisioner "local-exec" {
    command = templatefile("linux-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/shnkey"
    })
    interpreter = ["bash", "-c"]
  }

  lifecycle {
    ignore_changes = [
      ami, tags
    ]
  }

  tags = {
    Name  = "SHN PA Connector"
    Owner = "demo"
  }
}

# Create Elastic IP for the PA Connector
resource "aws_eip" "shn_pa_connector_eip" {
  vpc = true
  tags = {
    Name  = "shn_pa_connector_eip"
    Owner = "demo"
  }
}

# Associate Elastic IP to PA Connector
resource "aws_eip_association" "shn_pa_connector_eip_association" {
  instance_id   = aws_instance.shn_pa_connector.id
  allocation_id = aws_eip.shn_pa_connector_eip.id
}