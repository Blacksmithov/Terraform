#имена серверов, которые необходимо создать
variable "devs" {
   type    = list(string)
   default = ["pc1-blacksmithov"]
}

#путь репозитория, который необходимо загрузить на сервер. Если в этом нет необходимости - удалите ссылки
variable "git_ssh" {
   default = "github.com/Blacksmithov/Terraform"
}

#имя ветки, которую необходимо загрузить
variable "git_branch" {
   default = "DigitalOceanDroplet"
}
# переменные для доступа к репозиторию
variable "git_username" {}
variable "git_password" {}

#путь к файлу. который необходимо загрузить на удаленный сервер. Если не нужно - удалить
variable "copy_key" {
  default = "C:/vps_do/configs/key.json"
}

#тело публичного ключа, который будет загружен на сервер и на основании него предоставлен доступ
variable "my_body_key" {}


##########################токены############################
variable "do_token" {}

##########################провайдеры##########################
provider "digitalocean" {
  token = var.do_token
}

##########################работа с ключами##########################
resource "digitalocean_ssh_key" "BLACKSMITHOV_SSH_PUB_VPS" {
  name = "BLACKSMITHOV.SSH.PUB.VPS"
  public_key = var.my_body_key
}

##########################создание VPS##########################
locals{
    devs = { for v in var.devs : index(var.devs, v) => v }
}

resource "digitalocean_tag" "serv_tag" {
  name = "module:devops_email:maxk_at_bk_ru"
}

resource "digitalocean_droplet" "new_server" {
  for_each     = local.devs
  name         = each.value
  image        = "centos-7-x64"
  region       = "ams3"
  size         = "s-1vcpu-1gb"
  tags         = [digitalocean_tag.serv_tag.id]
  ssh_keys     = [digitalocean_ssh_key.BLACKSMITHOV_SSH_PUB_VPS.id] 
  
  
  
   provisioner "remote-exec" {
     inline = [
       "sudo yum -y install git && sudo yum -y install epel-release && sudo yum -y install ansible && git clone --branch ${var.git_branch} https://${var.git_username}:${var.git_password}@${var.git_ssh} && yum install -y mc && git config --global user.name Blacksmithov && git config --global user.email maxk@bk.ru && sudo yum -y install wget unzip && wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip && sudo unzip ./terraform_0.12.24_linux_amd64.zip -d /usr/local/bin/"	 	   
     ]

     connection {
       type        = "ssh"
       user        = "root"
       host        = self.ipv4_address
       private_key = file("c:/ssh/id_rsa")
     }
  
   }
  
  provisioner "file" {
    source      = var.copy_config
    destination = "/root/ansible/terraform.tfvars"
	
	connection {
       type        = "ssh"
       user        = "root"
       host        = self.ipv4_address
       private_key = file("c:/ssh/id_rsa")
     }
  }
  
  provisioner "file" {
    source      = var.copy_key
    destination = "/root/ansible/key.json"
	
	connection {
       type        = "ssh"
       user        = "root"
       host        = self.ipv4_address
       private_key = file("c:/ssh/id_rsa")
     }
  }
  
  provisioner "local-exec" {
    command = "cmd /c putty root@${self.ipv4_address}"	
  } 
    
}

