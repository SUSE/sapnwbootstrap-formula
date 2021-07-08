{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

# the sid, instance number pair of a node is unique, so we need to adapt configuration
# in non-HA use case create ASCS|ERS|PAS|AAS configuration
# in HA use case create additional ASCS|ERS configuration on ERS|ASCS
{% for node in netweaver.nodes if host == node.host or (netweaver.ha_enabled and node.sap_instance in ['ascs', 'ers']) and node.sap_instance != "db" %}

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
# on HA use case deploy ASCS|ERS on ERS|ASCS
{% if netweaver.ha_enabled and node.sap_instance in ["ascs", "ers"] %}
    - onlyif:
      - test -d /usr/sap/{{ node.sid }}/ASCS* || test -d /usr/sap/{{ node.sid }}/ERS*
{% endif %}

# do not enable ASCS and ERS exporter service in HA use case (handled by pacemaker)
{% if netweaver.ha_enabled and node.sap_instance in ['ascs', 'ers'] %}
{% set service_status = "disabled" %}
{% set service_enabled = False %}
{% else %}
{% set service_status = "running" %}
{% set service_enabled = True %}
{% endif %}

sap_host_exporter_service_{{ exporter_instance }}:
  service.{{ service_status }}:
    - name: prometheus-sap_host_exporter@{{ exporter_instance }}
    - enable: {{ service_enabled }}
    - restart: True
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
      - file: sap_host_exporter_configuration_{{ exporter_instance }}
# on HA use case deploy ASCS|ERS on ERS|ASCS
{% if netweaver.ha_enabled and node.sap_instance in ["ascs", "ers"] %}
    - onlyif:
      - test -d /usr/sap/{{ node.sid }}/ASCS* || test -d /usr/sap/{{ node.sid }}/ERS*
# on non-HA use case watch file for changes (not possible for disabled service)
{% else %}
    - watch:
      - file: sap_host_exporter_configuration_{{ exporter_instance }}
{% endif %}

{% endfor %}
