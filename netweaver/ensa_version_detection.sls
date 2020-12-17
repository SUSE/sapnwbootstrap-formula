{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host and node.sap_instance in ['ascs', 'ers'] %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name = node.sid~'_'~instance %}

# This state sets the `ensa_version` grain
set_ensa_version_data_in_grains_{{ instance_name }}:
  netweaver.ensa_version_grains_present:
    - name: {{ node.sap_instance }}
    - sid: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - require:
      - netweaver_install_{{ instance_name }}

{% endfor %}
