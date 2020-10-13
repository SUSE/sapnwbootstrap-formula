{% from "netweaver/map.jinja" import netweaver with context %}

include:
  - netweaver.pre_validation
  - netweaver.setup
  - netweaver.saptune
  - netweaver.extract_nw_archives
  - netweaver.install_pydbapi
  - netweaver.install_ascs
  - netweaver.install_ers
  - netweaver.ensa_version_detection
  - netweaver.ha_cluster
  - netweaver.install_db
  - netweaver.install_pas
  - netweaver.install_aas
  {%- if netweaver.monitoring_enabled %}
  - netweaver.monitoring
  {%- endif %}
