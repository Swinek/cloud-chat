terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
  region              = "eu-stockholm-1" # Change if you selected a different region
}

# ==========================================
# ENTER YOUR DATA HERE
# ==========================================
locals {
  # 1. Your OCID
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaapfkyfv3gvs3fugmdobuwcnkm2ifygv64rlmh4vappmaeswzt53mq"
  
  ad_name        = "Sbmw:EU-STOCKHOLM-1-AD-1"
  
  ssh_public_key_path = "~/.ssh/id_rsa.pub" 
}

resource "oci_core_vcn" "chat_vcn" {
  compartment_id = local.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "Chat_VCN"
}

resource "oci_core_internet_gateway" "chat_igw" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.chat_vcn.id
  enabled        = true
  display_name   = "Chat_Internet_Gateway"
}

resource "oci_core_default_route_table" "chat_route" {
  manage_default_resource_id = oci_core_vcn.chat_vcn.default_route_table_id
  route_rules {
    network_entity_id = oci_core_internet_gateway.chat_igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_default_security_list" "chat_security" {
  manage_default_resource_id = oci_core_vcn.chat_vcn.default_security_list_id

  ingress_security_rules {
    protocol    = "1" # ICMP (Ping)
    source      = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 3005
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "chat_subnet" {
  compartment_id    = local.compartment_id
  vcn_id            = oci_core_vcn.chat_vcn.id
  cidr_block        = "10.0.0.0/24"
  display_name      = "Chat_Subnet"
}

data "oci_core_images" "ubuntu_x86" {
  compartment_id           = local.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro" 
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "chat_server" {
  availability_domain = local.ad_name
  compartment_id      = local.compartment_id
  display_name        = "Chat_AMD_Server"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = oci_core_subnet.chat_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_x86.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(local.ssh_public_key_path)
  }
}

output "SERVER_PUBLIC_IP" {
  value       = oci_core_instance.chat_server.public_ip
  description = "This is the address of your new server!"
}