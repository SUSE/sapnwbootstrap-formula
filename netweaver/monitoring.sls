{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

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
      - file: sap_host_exporter_configuration

# for each node the instance number changes so we need to adapt configuration
{% for node in netweaver.nodes if host == node.host %}
sap_host_exporter_configuration:
  file.managed:
    - name: /etc/sap_host_exporter.yaml
    - contents: |
         port: "9680"
         address: "0.0.0.0"
         log-level: "info"
         sap-control-url: "http://127.0.0.1:5{{ node.instance }}13"
         sap-control-user: "{{ node.sid.lower() }}adm"
         sap-control-password: "{{ netweaver.sid_adm_password|default(netweaver.master_password) }}"
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
{% endfor %}
