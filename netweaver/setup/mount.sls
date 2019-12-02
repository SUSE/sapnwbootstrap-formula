{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

{% if node.sap_instance.lower() in ['ascs', 'ers'] %}

{% if ':' in node.shared_disk_dev %} # This means that the device is a nfs share
{% set device = node.shared_disk_dev %}
{% set fstype = 'nfs4' %}
{% else %}
# device is shared_device_disk2 for ascs or shared_device_disk3 for ers
{% set device = node.shared_disk_dev~'2' if node.sap_instance.lower() == 'ascs' else node.shared_disk_dev~'3' %}
{% set fstype = 'xfs' %}
{% endif %}

mount_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  mount.mounted:
    - name: /usr/sap/{{ node.sid.upper() }}/{{ node.sap_instance.upper() }}{{ instance }}
    - device: {{ device }}
    - fstype: {{ fstype }}
    - mkmnt: True
    - opts:
      - defaults

{% elif node.sap_instance.lower() in ['pas', 'aas'] %}

create_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/D{{ instance }}

{% endif %}
{% endfor %}
