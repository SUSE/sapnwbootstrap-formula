{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

{% if node.sap_instance.lower() in ['ascs', 'ers'] %}

create_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/{{ node.sap_instance.upper() }}{{ instance }}

# HA scenario where ASCS and ERS must share a disk to start/stop the processes as cluster
{% if node.shared_disk_dev is defined %}

{% if ':' in node.shared_disk_dev %} # This means that the device is a nfs share
{% set device = node.shared_disk_dev %}
{% set fstype = netweaver.nfs_version %}
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
      - {{ netweaver.nfs_options }}

# This second loop is used to find ASCS/ERS shared instances to create the opposite instance folder
{% for shared_node in netweaver.nodes if host != shared_node.host and shared_node.sid == node.sid and shared_node.sap_instance.lower() in ['ascs', 'ers'] %}

{% set shared_instance = '{:0>2}'.format(shared_node.instance) %}
{% set shared_instance_name =  shared_node.sid~'_'~shared_instance %}

create_folder_{{ shared_node.sap_instance.lower() }}_{{ shared_instance_name }}:
  file.directory:
    - name: /usr/sap/{{ shared_node.sid.upper() }}/{{ shared_node.sap_instance.upper() }}{{ shared_instance }}

{% endfor %}
{% endif %}

{% elif node.sap_instance.lower() in ['pas', 'aas'] %}

create_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/D{{ instance }}

{% endif %}
{% endfor %}
