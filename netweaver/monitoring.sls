{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

# the sid, instance number pair of a node is unique, so we need to adapt configuration
{% for node in netweaver.nodes if host == node.host and node.sap_instance != "db" %}
{% set sap_instance_nr = '{:0>2}'.format(node.instance) %}
{% set exporter_instance = '{}_{}{}'.format(node.sid, node.sap_instance.upper(), sap_instance_nr) %}
{% set instance_name = node.sid~'_'~sap_instance_nr %}

# we bind each exporter instance to a SAP instance virtual host
sap_host_exporter_configuration_{{ exporter_instance }}:
  file.managed:
    - name: /etc/sap_host_exporter/{{ exporter_instance }}.yaml
    - contents: |
         address: {{ node.virtual_host }}
         sap-control-uds: /tmp/.sapstream5{{ sap_instance_nr }}13
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
      - netweaver_install_{{ instance_name }}

sap_host_exporter_service_{{ exporter_instance }}:
  service.running:
    - name: prometheus-sap_host_exporter@{{ exporter_instance }}
    - enable: {{ not netweaver.ha_enabled }}
    - restart: True
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
      - file: sap_host_exporter_configuration_{{ exporter_instance }}
    - watch:
      - file: sap_host_exporter_configuration_{{ exporter_instance }}

{% endfor %}
