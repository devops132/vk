######Подключаем провайдер######

terraform {
  required_providers {
    vkcs = {
      source  = "hub.mcs.mail.ru/repository/vkcs" #Папка должна называтся так же
    }
  }
}

provider "vkcs" {
    username   = var.user #Задается в файле terraform.tfvars
    password   = var.pass #Задается в файле terraform.tfvars
    project_id = "1e19d04afd0a476ca0898de2b3658631"  #Настройки проекта -> Terraform
  }

################################

######Создаем сети######

# Глобальная сеть
resource "vkcs_networking_network" "network_1" {
  name           = "network_1" #Любое имя
}

# Подсеть. Подсетей в одной сети может быть сколько угодно
resource "vkcs_networking_subnet" "subnet_1" {
  name       = "subnet_1" #Абсолютно любое имя
  network_id = "${vkcs_networking_network.network_1.id}" #Тут получаем id нашей сети. Если название сети другое -- надо его поменять с network_1 на свое
  cidr       = "192.168.199.0/24" #Подсеть, какая нравится
  ip_version = 4 #Тут понятно
}

################################

######Настраиваем безопасность######

# Группа безопасности (файрвол)
resource "vkcs_networking_secgroup" "secgroup_1" {
  name        = "secgroup_1" #Любое имя, абсолютно
}

#Правила для группы безопасности
resource "vkcs_networking_secgroup_rule" "allow_ssh" {
  direction         = "ingress" #Входящий трафик. Если нужен исходящий, пишем degress
  ethertype         = "IPv4" #Тут понятно
  protocol          = "tcp" #tcp udp icmp ah dccp egp esp gre igmp ipv6-encap ipv6-frag ipv6-icmp ipv6-nonxt ipv6-opts ipv6-route ospf pgm rsvp sctp udplite vrrp 
  port_range_min    = 22 #Открывать он умеет только диапазонами портов. Тут пишется начальный
  port_range_max    = 22 #Тут пишется конечный
  remote_ip_prefix  = "0.0.0.0/0" #Сеть, трафик из которой должен попадать под правило
  security_group_id = "${vkcs_networking_secgroup.secgroup_1.id}" #Если у sg другое название -- меняй secgroup_1 на свое
}

resource "vkcs_networking_secgroup_rule" "allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${vkcs_networking_secgroup.secgroup_1.id}"
}

resource "vkcs_networking_secgroup_rule" "allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${vkcs_networking_secgroup.secgroup_1.id}"
}

resource "vkcs_networking_secgroup_rule" "allow_ping" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${vkcs_networking_secgroup.secgroup_1.id}"
}

#Привязываем группу безопасности к сетевому порту вм
resource "vkcs_networking_port_secgroup_associate" "ass_1" {
  port_id = "${vkcs_networking_port.port_1.id}" #Порт создается ниже. Другое название -- меняй port_1 на свое
  security_group_ids = [
    "${vkcs_networking_secgroup.secgroup_1.id}", #Аналогично с названиями sg
  ]
}

################################

#Создаем сетевой порт для вм
#У каждой вм должен быть свой порт
#Создаешь еще вм -- создавай еще порт
#Сеть, подсеть, группу безопасности, можно назначать одну и ту же
resource "vkcs_networking_port" "port_1" {
  name               = "port_1" #Любое имя
  network_id         = "${vkcs_networking_network.network_1.id}" #ID сети, смотри названия внимательно
  admin_state_up     = "true" #Включили
  security_group_ids = ["${vkcs_networking_secgroup.secgroup_1.id}"] #ID sg, с названиями не тупи

  fixed_ip {
    subnet_id  = "${vkcs_networking_subnet.subnet_1.id}" #ID подсети, не теряй названия
    ip_address = "192.168.199.10" #Адрес, котторый мы ставим на машину
  }
}

#Создаем роутер
#Роутер нужен только один
resource "vkcs_networking_router" "router_1" {
  name                = "router_1" #любое имя
  admin_state_up      = true #Включили
  external_network_id = "298117ae-3fa4-4109-9e08-8be5602be5a2" #идешь в сети, там будет внешняя сеть default. Под ней сереньким написан айдишник, вот его и впиши сюда
}

#Создаем интерфейс роутера
#Внимателььно смотри на названия
#Как я понял, интерфейс роутеру нужен только один
resource "vkcs_networking_router_interface" "router_interface_1" {
  router_id = "${vkcs_networking_router.router_1.id}"
  subnet_id = "${vkcs_networking_subnet.subnet_1.id}"
}

#Создаем внешний ip адрес
#На каждую машину и балансировщик нужен новый адрес
#Хочешь больше машин -- копируй
#Хочешь больше балансировщиков -- тоже копируй
#Не забудь поменять название ресурса
resource "vkcs_networking_floatingip" "floatip_1" {
  pool = "ext-net" #Название по умолчанию у всех
}

#Создаем привязку внешнего адреса к машине и внутреннему адресу (NAT)
#Тут главное не продолбай названия
#Такую штуку надо делать для каждой вм кстати
#Хочешь больше машин -- копируй
resource "vkcs_compute_floatingip_associate" "fip_1" {
  floating_ip = "${vkcs_networking_floatingip.floatip_1.address}"
  instance_id = "${vkcs_compute_instance.instance1.id}"
  fixed_ip    = "${vkcs_compute_instance.instance1.network[0].fixed_ip_v4}"
}

################################

######Создаем машину#######

#Сама машина
#Хочешь больше машин -- копируй
resource "vkcs_compute_instance" "instance1" {
  name            = "instance1" #Любое имя
  image_id        = var.image_id #openstack image list
  flavor_id       = var.flavor_id #openstack flavor list
  user_data = file("cloud_init.cfg") #Иначе не создаст юзера и ты не сможешь зайти. Смотри сам файл, там все понятно. Файл должен лежать в папке проекта (рядом с main.tf)

  network {
    port = "${vkcs_networking_port.port_1.id}" #Назначаем порт, не продолбай его название
  }
}

################################



################################

#Создаем сетевой порт для балансировщика
resource "vkcs_networking_port" "port_lb" {
  name               = "port_lb" #Любое имя
  network_id         = "${vkcs_networking_network.network_1.id}" #Сеть должна быть одна с вмками
  admin_state_up     = "true" #Включили
  security_group_ids = ["${vkcs_networking_secgroup.secgroup_1.id}"]

  fixed_ip {
    subnet_id  = "${vkcs_networking_subnet.subnet_1.id}" #Сеть одна с вмками
    ip_address = "192.168.199.100" #Внутренний адрес в этой сети, желательно, свободный
  }
}

#Создаем внешний адрес для балансировщика
resource "vkcs_networking_floatingip" "floatip_lb" {
  pool = "ext-net"
}

#Привязываем адрес к балансировщику
resource "vkcs_networking_floatingip_associate" "fip_1" {
  floating_ip = "${vkcs_networking_floatingip.floatip_lb.address}"
  port_id     = "${vkcs_networking_port.port_lb.id}"
  depends_on = [
    vkcs_networking_port.port_lb
  ]
}

#Создаем балансировщик
resource "vkcs_lb_loadbalancer" "loadbalancer" {
  name = "loadbalancer"
  vip_subnet_id = "${vkcs_networking_subnet.subnet_1.id}"
  vip_port_id = "${vkcs_networking_port.port_lb.id}" 
  vip_network_id = "${vkcs_networking_network.network_1.id}"
}

#Создаем слушатель
resource "vkcs_lb_listener" "listener" {
  name = "listener" #Любое имя
  protocol = "HTTP" #Протокол, по которому идут к нам. Можно http, https, tcp
  protocol_port = 80 #Порт, на который будут стучать клиенты
  loadbalancer_id = "${vkcs_lb_loadbalancer.loadbalancer.id}"
}

#Создаем пул
resource "vkcs_lb_pool" "pool" {
  name = "pool" #Любое имя
  protocol = "HTTP" #Протокол, по которому коннектимся к бэкэнду. Можно http, https, tcp
  lb_method = "ROUND_ROBIN" #ROUND_ROBIN, LEAST_CONNECTIONS, SOURCE_IP, or SOURCE_IP_PORT.
  listener_id = "${vkcs_lb_listener.listener.id}"
}

#Добавляем инстансы
#Нужно балансировать больше вмок -- копируй
resource "vkcs_lb_member" "member_1" {
  address = "192.168.199.10" #Адрес нашей вмки
  protocol_port = 80 #Порт, на котором слушает приложение на вм
  pool_id = "${vkcs_lb_pool.pool.id}"
  subnet_id = "${vkcs_networking_subnet.subnet_1.id}"
  weight = 1 #Больше вес -- больше запросов уходит на этот хост
}



#Вывод инфы о машине
# Синтаксис: имяресурса.названиересурса.параметр
output "instance1_ip" {
  value = vkcs_networking_floatingip.floatip_1.address 
}

#Вывод инфы о балансировщике
output "loadbalancer_ip" {
  value = vkcs_networking_floatingip.floatip_lb.address 
}