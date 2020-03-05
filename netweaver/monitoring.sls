prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

sap_host_exporter_exporter_service:
  service.running:
    - name: prometheus-sap_host_exporter
    - enable: True
    - restart: True
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
