{%- from "netweaver/map.jinja" import netweaver with context -%}

{% for node in netweaver.nodes if host == node.host %}

prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

# for each node the instance number change so we need to adapt configuration
sap_host_exporter_configuration:
  file.managed:
    - name: /etc/sap_host_exporter.yaml
    - contents: |
         port: "9680"
         addres: "0.0.0.0"
         log-level: "info"
         sap-control-url: "http://127.0.0.1:5{{ node.instance }}13"
         sap-control-user:  "{{netweaver.sap_host_exporter.sap_control_user}}"
         sap-control-password: "{{netweaver.sap_host_exporter.sap_control_password}}"
    - require:
      - pkg: prometheus_sap_host_exporter_pkg


sap_host_exporter_exporter_service:
  service.running:
    - name: prometheus-sap_host_exporter
    - enable: True
    - restart: True
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
      - file: sap_host_exporter_configuration

{% endfor %}