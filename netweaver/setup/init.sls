{%- from "netweaver/map.jinja" import netweaver with context -%}

include:
{% if netweaver.install_packages is sameas true %}
  - netweaver.setup.packages
{% endif %}
  - netweaver.setup.shared_disk
  - netweaver.setup.virtual_addresses
  - netweaver.setup.sap_nfs
  - netweaver.setup.mount
  - netweaver.setup.users
  - netweaver.setup.swap_space
