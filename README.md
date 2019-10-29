# SAP Netweaver salt formula

Salt formula for bootstrapping and managing SAP Netweaver platform. Currently the next SAP Netweaver components are available:

- ASCS instance
- ERS instance
- PAS instance
- AAS instance
- Database instance (this adds the required users, tables, views, etc to the current Hana database)

The formula follows the best practices defined in the official [SUSE documentation](https://www.suse.com/media/white-paper/sap_netweaver_availability_cluster_740_setup_guide.pdf?_ga=2.211949268.1511104453.1571203291-1421744106.1546416539).

**Disclaimer: the formula only works with SAP Hana as database.**

## Installation

The package can be installed copying the content directly to the configure salt `file_roots` or via zypper in SUSE distributions.

    # To use a development version
    # zypper ar https://build.opensuse.org/project/show/network:ha-clustering:Factory ha-cluster

    zypper in sapnwbootstrap-formula

## Usage

The formula has some hard dependencies and all of them must be in place for a successful netweaver deployment.

- In order to deploy a correct Netweaver environment a NFS share is needed (SAP stores some shared files there). The NFS share must have the folders `sapmnt` and `usrsapsys` in the exposed folder. It's a good practice the store this folder with the Netweaver SID name (for example `/sapdata/HA1/sapmnt` and `/sapdata/HA1/usrsapsys`). **This subfolders content is removed by default during the deployment**.

- Netweaver installation software (`swpm`) must be available in `swpm_media` variable in the pillar file pointing a NFS share. This folder must contain the `swpm` and `sapexe` folders (optionally the `Netweaver Export` and `HANA HDB Client` folder if the Database, PAS and AAS instances are installed).

- The optimal deployment requires 4 machines in the same network for each of the Netweaver instances (the DB instance can be installed anywhere after ASCS and ERS are installed).

- SAP Hana database must be up and running.

Find an example about all of the possible configurable options in the [pillar.example](pillar.example) file.

## License

See the [LICENSE](LICENSE) file for license rights and limitations.

## Author

Xabier Arbulu Insausti (xarbulu@suse.com)

## Reviewers

*Pull request* preferred reviewers for this project:
- Xabier Arbulu Insausti (xarbulu@suse.com)
