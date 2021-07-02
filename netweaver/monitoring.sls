{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

# the sid, instance number pair of a node is unique, so we need to adapt configuration
# do not create configuration for "sap_instance: db"
{% for node in netweaver.nodes if node.sap_instance != "db" %}
# create ASCS|ERS|PAS|AAS configuration in non-HA use case
# OR create both ASCS and ERS configuration in HA use case
#   AND deploy PAS exporter on ASCS/PAS host if no dedicated PAS host is used
{% if (not netweaver.ha_enabled and host == node.host) or (netweaver.ha_enabled and (node.sap_instance in ['ascs', 'ers'] or host == node.host)) %}
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

# do not run ASCS and ERS exporter service in HA use case (handled by pacemaker)
# only run PAS exporter in HA use case (if no dedicated PAS host is used)
{% if not netweaver.ha_enabled or node.sap_instance == 'pas' %}
sap_host_exporter_service_{{ exporter_instance }}:
  service.running:
    - name: prometheus-sap_host_exporter@{{ exporter_instance }}
    - enable: True
    - restart: True
    - require:
      - netweaver_install_{{ instance_name }}
      - pkg: prometheus_sap_host_exporter_pkg
      - file: sap_host_exporter_configuration_{{ exporter_instance }}
    - watch:
      - file: sap_host_exporter_configuration_{{ exporter_instance }}
{% endif %}

{% endif %}
{% endfor %}
