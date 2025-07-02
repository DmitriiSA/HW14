terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.13"
    }
  }

  required_version = ">= 0.13"
}
// Configure the Yandex Cloud Provider (Basic)
//
provider "yandex" {
  token     = "y0__xDp17ICGMHdEyDZlYPaE6oOaUU3fGGY1-SZRpw9rbEgUVcA"
  cloud_id  = "b1g21ko4q22qq9nssbl1"
  folder_id = "b1ghfja4e1sdv347eqa6"
  zone      = "ru-central1-d"
}

// Auxiliary resources for Compute Instance
resource "yandex_vpc_network" "default" {}

resource "yandex_vpc_subnet" "default-ru-central1-d" {
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.130.0.0/24"]
}

// Create a new Compute Instance ( Java, Maven and Git)
//
resource "yandex_compute_instance" "build" {
  name        = "build-instance"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 50
  }

  boot_disk {
      initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # ОС Ubuntu 20.04 LTS
      size     =  7
      type     = "network-ssd"
    }
  }

  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.default-ru-central1-d.id
    //nat_ip_version = ipv4
    nat = true
    ipv4 = true
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
       user-data = <<-EOF
      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - default-jdk
        - maven
        - git
      runcmd:
        - git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git /tmp/hello
        - cd /tmp/hello && mvn package
        - mkdir -p /var/www/html
        - cp /tmp/hello/target/hello-1.0.war /var/www/html/
        - apt-get install -y nginx
        - systemctl start nginx
      EOF

  }
}

// Create a new Prod Instance ( Java, tomcat)
//
resource "yandex_compute_instance" "prod" {
  name        = "prod-instance"
  platform_id = "standard-v3"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 50
  }

  boot_disk {
      initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # ОС Ubuntu 20.04 LTS
      size     =  7
      type     = "network-ssd"
    }
  }

  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.default-ru-central1-d.id
    //nat_ip_version = ipv4
    nat = true
    ipv4 = true
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
        user-data = <<-EOF
      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - default-jdk
        - tomcat9
      runcmd:
        - while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
        - apt-get install -y wget
        - wget http://${yandex_compute_instance.build.network_interface.0.nat_ip_address}/hello-1.0.war -O /var/lib/tomcat9/webapps/hello.war
        - systemctl restart tomcat9
      EOF
  }
  depends_on = [yandex_compute_instance.build]
}
output "build_instance_ip" {
  value = yandex_compute_instance.build.network_interface.0.nat_ip_address
}

output "prod_instance_ip" {
  value = yandex_compute_instance.prod.network_interface.0.nat_ip_address
  description = "Access the application at: http://<prod_ip>:8080/hello/"
}

