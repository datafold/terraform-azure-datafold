# Changelog

See this file for notable changes between versions.

### [1.1.1](https://github.com/datafold/terraform-azure-datafold/compare/v1.1.0...v1.1.1) (2025-11-04)


### Bug Fixes

* Azure LB deploy ([aafbecd](https://github.com/datafold/terraform-azure-datafold/commit/aafbecdd80cdb63e11748b8fd29ccc14256df5f5))

## [1.1.0](https://github.com/datafold/terraform-azure-datafold/compare/v1.0.0...v1.1.0) (2025-08-05)


### Features

* Add capabilities to override all resource names ([9048d44](https://github.com/datafold/terraform-azure-datafold/commit/9048d4449277b8eb630d86d862e9e69458e49074))

## 1.0.0 (2025-07-04)


### Features

* Add capability to connect to k8s API over public internet through whitelisting and jumpbox ([a0daa0e](https://github.com/datafold/terraform-azure-datafold/commit/a0daa0ea7778cef7c65f3fc8c241112deba27a69))
* Add clickhouse backup setup ([418bc82](https://github.com/datafold/terraform-azure-datafold/commit/418bc8213a948f9797affa47a1b55173eb945a64))
* Add labels to custom nodes ([1f709f1](https://github.com/datafold/terraform-azure-datafold/commit/1f709f1d5e6ace3f77b5224bd274b3fa6d6b6b64))
* Add network, load_balancer, key_vault, identity, database, aks modules ([46bff42](https://github.com/datafold/terraform-azure-datafold/commit/46bff4289e083721073268b04fb23639462e8e1b))
* Add required outputs for helm chart ([15644f3](https://github.com/datafold/terraform-azure-datafold/commit/15644f3f39188253df9d9d5ecf0a08964b287385))
* Enable auto-scaling ([51a167e](https://github.com/datafold/terraform-azure-datafold/commit/51a167ef01f93656fcd731435ea3b529d802c9dd))
* Enable optional deployment of ADLS with private link ([8e4174b](https://github.com/datafold/terraform-azure-datafold/commit/8e4174b04962b7298d34b416d7e1e5e8fa72abed))
* Make load balancing work with SSL ([24749d6](https://github.com/datafold/terraform-azure-datafold/commit/24749d6f7c33e85090902b86ddb422bff9a232f7))
* Make sbunet CIDRs dynamic with possibility of an override ([fab452a](https://github.com/datafold/terraform-azure-datafold/commit/fab452a9510806b23c3f24d788a9c6fed6189a0d))
* Support more flexible nodes and deployment ([f949142](https://github.com/datafold/terraform-azure-datafold/commit/f949142b647e67525f18a128e41107b2f5d3c350))


### Bug Fixes

* Add outputs for VPN attributes ([754f54b](https://github.com/datafold/terraform-azure-datafold/commit/754f54b0a96bb599314da39ed227482f6595bf99))
* Create SSL cert on Application Gateway and manage Application Gateway frontend port and listener from kubernetes with AGIC ([37ce2fc](https://github.com/datafold/terraform-azure-datafold/commit/37ce2fcb5f5dccb40a82fb3d5d4de9d89cff8fc4))
* Prevent recreation of nodes by terraform for no reason ([16250cf](https://github.com/datafold/terraform-azure-datafold/commit/16250cf83f7cb9da14a814e160219a117e1482e3))
* Several azure fixes ([9ec0a82](https://github.com/datafold/terraform-azure-datafold/commit/9ec0a82884848dde416da461b58117cf0ea80bb7))
