{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

{% if node.sap_instance.lower() == 'ascs' %}

create_ascs_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/ASCS{{ instance }}

{% elif node.sap_instance.lower() == 'ers' %}

create_ers_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/ERS{{ instance }}

{% elif node.sap_instance.lower() in ['pas', 'aas'] %}

create_dialog_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/D{{ instance }}

{% endif %}
{% endfor %}
