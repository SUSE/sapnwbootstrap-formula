include:
  - netweaver.setup
  - netweaver.saptune
  - netweaver.install_ascs
  - netweaver.install_ers
  - netweaver.ha_cluster
  - netweaver.install_db
  - netweaver.install_pas
  - netweaver.install_aas
  {% if netweaver.sap_host_exporter is defined and netweaver.sap_host_exporter is sameas true %}
  - netweaver.monitoring
  {% endif %}
