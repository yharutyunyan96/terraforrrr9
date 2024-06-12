# Get AMI id here
data "aws_ami" "server_ami" {
  most_recent      = true
  owners           = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "random_id" "sc_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

# resource "aws_key_pair" "sc_auth" {
#   key_name   = var.key_name
#   public_key = file(var.public_key_path)
# }

# for jenkis use this resource / just hardcode the public key as jenkins doesn't have permission
resource "aws_key_pair" "sc_auth" {
  key_name   = "sc-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQChUgy88KJv5Eora/2wNwzuw8aP/jnD1kFgRTp25MM4U4He+XYXfEXdlQsMSXDnXIfUrWHtf477lUpgM8IicdK/QpAJ8p+phFq0Y7d8hyt1wn5rzERxpWq7XTDzDl49/P6Ap/3QPY6VR/lv9pzUfG/sg33E9836b0gbKKIPPZuqB/6cfK9qtcCr2gGLr3K5ItkL50E6acVxOohpzt0wNy9Ar0Ge8fdOFgzPnK6BRAc6lUJXB4jtccBeno1bZat3kMsVMjoLa3GRvWl3FStkFRUwvan0thL1mfRuVvf0qZsgxw+826Ef+xxMxtQ1t7c9QFQzhM4L9tZuddO1HSguc0vyzC8oxJEc6Es/Cfj8QtcYzU2Lfr9C3idJi7sZFFmGJJZ+EI1xsKBRczjx2XzdwFpd1ByQVMOxFxMJUnSDu+3o9zRHYUB7YTdKDdfrVPs/57KOGB78UTjPJAPjDcn8cpCCI9ipzZURIgTFxMjrcxZyOano6VoXCqdN0rFBz6cuLvzPgkkv0zekplTm7f+jkSawSonU5xq4H7VGQXGCuHzuczLnuET7kBTKEhb6a8hRAMU9kABiNMK1irwQM0pGpfyuKnKE1ErnLrnv/oyxYb4mx18g0IolffrYyhDP8b/6rcn4ByU9PXvIIxNWrNAv2ghgFAs25nTzkm4rrrsfCuyj5Q== ubuntu@ip-172-31-60-229"
}

resource "aws_instance" "sc_main_instance" {
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id
  vpc_security_group_ids = [aws_security_group.sc_sg.id]
  subnet_id              = aws_subnet.sc_public_subnet[count.index].id
  key_name               = aws_key_pair.sc_auth.id

  tags = {
    Name = "sc_main_instance-${random_id.sc_node_id[count.index].dec}"
  }

  # we will do the same trough ansible
  # user_data = templatefile("./main-userdata.tpl", { new_hostname = "sc-main-${random_id.sc_node_id[count.index].dec}" })

  root_block_device {
    volume_size = var.main_vol_size
  }

  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-east-1"
  }

  # provisioner "local-exec" {
  #   command = "printf '\n${self.public_ip}' >> aws_hosts"
  # }
  
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }
}

# comment when whorking with Jenkins
# resource "null_resource" "main-playbook" {
#   depends_on = [aws_instance.sc_main_instance]
#   provisioner "local-exec" {
#     command = "ansible-playbook -i aws_hosts --key-file /home/ubuntu/.ssh/id_rsa /home/ubuntu/environment/terraform-ansible/playbooks/main-playbook.yml"
#   }
# }

output "grafana_access" {
  value = { for i in aws_instance.sc_main_instance[*] : i.tags.Name => "${i.public_ip}:3000" }
}

# output "instance_ips" {
#   value = [for i in aws_instance.sc_main_instance[*]: i.public_ip]
# }

# output "instance_ids" {
#   value = [for i in aws_instance.sc_main_instance[*]: i.id]
# }