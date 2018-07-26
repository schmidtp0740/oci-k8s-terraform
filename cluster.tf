variable "cluster_kubernetes_version" {
  default = "v1.8.11"
}

variable "cluster_name" {
  default = "tfTestCluster"
}

variable "cluster_options_add_ons_is_kubernetes_dashboard_enabled" {
  default = true
}

variable "cluster_options_add_ons_is_tiller_enabled" {
  default = true
}

variable "cluster_options_kubernetes_network_config_pods_cidr" {
  default = "10.1.0.0/16"
}

variable "cluster_options_kubernetes_network_config_services_cidr" {
  default = "10.2.0.0/16"
}

variable "node_pool_initial_node_labels_key" {
  default = "key"
}

variable "node_pool_initial_node_labels_value" {
  default = "value"
}

variable "node_pool_kubernetes_version" {
  default = "v1.8.11"
}

variable "node_pool_name" {
  default = "iaasPool"
}

variable "node_pool_node_image_name" {
  default = "Oracle-Linux-7.4"
}

variable "node_pool_node_shape" {
  default = "VM.Standard2.24"
}

variable "node_pool_quantity_per_subnet" {
  default = 5
}

data "oci_identity_availability_domains" "test_availability_domains" {
  compartment_id = "${var.compartment_ocid}"
}

resource "oci_core_virtual_network" "test_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "VcnForIaaSClusters"
}

resource "oci_core_internet_gateway" "gateway0" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "gateway0"
  vcn_id         = "${oci_core_virtual_network.test_vcn.id}"
}

resource "oci_core_route_table" "routetable0" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.test_vcn.id}"
  display_name   = "routetable0"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.gateway0.id}"
  }
}

resource "oci_core_security_list" "workersSecurityList" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.test_vcn.id}"
  display_name   = "workersSecurityList"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  egress_security_rules {
    destination = "10.0.10.0/24"
    protocol    = "all"
    stateless   = true
  }

  egress_security_rules {
    destination = "10.0.11.0/24"
    protocol    = "all"
    stateless   = true
  }

  egress_security_rules {
    destination = "10.0.12.0/24"
    protocol    = "all"
    stateless   = true
  }

  // allow inbound ssh traffic from a specific port
  ingress_security_rules {
    protocol  = "all"          // tcp
    source    = "10.0.10.0/24"
    stateless = true
  }

  ingress_security_rules {
    protocol  = "all"          // tcp
    source    = "10.0.11.0/24"
    stateless = true
  }

  ingress_security_rules {
    protocol  = "all"          // tcp
    source    = "10.0.12.0/24"
    stateless = true
  }

  ingress_security_rules {
    protocol  = "1"         // icmp
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  ingress_security_rules {
    protocol  = "6"             // tcp
    source    = "130.35.0.0/16"
    stateless = false

    tcp_options {
      // these represent destination port range
      "min" = 22
      "max" = 22
    }
  }

  ingress_security_rules {
    protocol  = "6"            // tcp
    source    = "138.1.0.0/17"
    stateless = false

    tcp_options {
      // these represent destination port range
      "min" = 22
      "max" = 22
    }
  }

  ingress_security_rules {
    protocol  = "6"         // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      // these represent destination port range
      "min" = 22
      "max" = 22
    }
  }

  ingress_security_rules {
    protocol  = "6"         // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      // these represent destination port range
      "min" = 30000
      "max" = 32767
    }
  }
}

resource "oci_core_security_list" "loadBalancerSecurityList" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.test_vcn.id}"
  display_name   = "loadbalancerSecurityList"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = true
  }

  // allow inbound ssh traffic from a specific port
  ingress_security_rules {
    protocol  = "all"       // tcp
    source    = "0.0.0.0/0"
    stateless = true
  }
}

resource "oci_core_subnet" "loadBalancersSubnet1" {
  #Required
  availability_domain = "${lookup(data.oci_identity_availability_domains.test_availability_domains.availability_domains[0],"name")}"
  cidr_block          = "10.0.20.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.test_vcn.id}"
  security_list_ids   = ["${oci_core_security_list.loadBalancerSecurityList.id}"]                                                    # Provider code tries to maintain compatibility with old versions.
  display_name        = "loadbalancers-1"
  route_table_id      = "${oci_core_route_table.routetable0.id}"
}

resource "oci_core_subnet" "loadBalancersSubnet2" {
  #Required
  availability_domain = "${lookup(data.oci_identity_availability_domains.test_availability_domains.availability_domains[1],"name")}"
  cidr_block          = "10.0.21.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.test_vcn.id}"
  display_name        = "loadbalancers-2"
  security_list_ids   = ["${oci_core_security_list.loadBalancerSecurityList.id}"]                                                    # Provider code tries to maintain compatibility with old versions.
  route_table_id      = "${oci_core_route_table.routetable0.id}"
}

resource "oci_core_subnet" "workersSubnet1" {
  #Required
  availability_domain = "${lookup(data.oci_identity_availability_domains.test_availability_domains.availability_domains[0],"name")}"
  cidr_block          = "10.0.10.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.test_vcn.id}"
  security_list_ids   = ["${oci_core_security_list.workersSecurityList.id}"]                                                         # Provider code tries to maintain compatibility with old versions.
  display_name        = "tfSubNet1ForNodePool"
  route_table_id      = "${oci_core_route_table.routetable0.id}"
}

resource "oci_core_subnet" "workersSubnet2" {
  #Required
  availability_domain = "${lookup(data.oci_identity_availability_domains.test_availability_domains.availability_domains[1],"name")}"
  cidr_block          = "10.0.11.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.test_vcn.id}"
  security_list_ids   = ["${oci_core_security_list.workersSecurityList.id}"]                                                         # Provider code tries to maintain compatibility with old versions.
  display_name        = "tfSubNet1ForNodePool"
  route_table_id      = "${oci_core_route_table.routetable0.id}"
}

resource "oci_core_subnet" "workersSubnet3" {
  #Required
  availability_domain = "${lookup(data.oci_identity_availability_domains.test_availability_domains.availability_domains[2],"name")}"
  cidr_block          = "10.0.12.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.test_vcn.id}"
  security_list_ids   = ["${oci_core_security_list.workersSecurityList.id}"]                                                         # Provider code tries to maintain compatibility with old versions.
  display_name        = "tfSubNet1ForNodePool"
  route_table_id      = "${oci_core_route_table.routetable0.id}"
}

resource "oci_containerengine_cluster" "test_cluster" {
  #Required
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "${var.cluster_kubernetes_version}"
  name               = "${var.cluster_name}"
  vcn_id             = "${oci_core_virtual_network.test_vcn.id}"

  #Optional
  options {
    service_lb_subnet_ids = ["${oci_core_subnet.loadBalancersSubnet1.id}", "${oci_core_subnet.loadBalancersSubnet2.id}"]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "${var.cluster_options_add_ons_is_kubernetes_dashboard_enabled}"
      is_tiller_enabled               = "${var.cluster_options_add_ons_is_tiller_enabled}"
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = "${var.cluster_options_kubernetes_network_config_pods_cidr}"
      services_cidr = "${var.cluster_options_kubernetes_network_config_services_cidr}"
    }
  }
}

resource "oci_containerengine_node_pool" "test_node_pool" {
  #Required
  cluster_id         = "${oci_containerengine_cluster.test_cluster.id}"
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "${var.node_pool_kubernetes_version}"
  name               = "${var.node_pool_name}"
  node_image_name    = "${var.node_pool_node_image_name}"
  node_shape         = "${var.node_pool_node_shape}"
  subnet_ids         = ["${oci_core_subnet.workersSubnet1.id}", "${oci_core_subnet.workersSubnet2.id}", "${oci_core_subnet.workersSubnet3.id}"]

  #Optional
  initial_node_labels {
    #Optional
    key   = "${var.node_pool_initial_node_labels_key}"
    value = "${var.node_pool_initial_node_labels_value}"
  }

  quantity_per_subnet = "${var.node_pool_quantity_per_subnet}"
  ssh_public_key      = "${var.ssh_public_key}"
}

output "cluster_id" {
  value = "${oci_containerengine_cluster.test_cluster.id}"
}
