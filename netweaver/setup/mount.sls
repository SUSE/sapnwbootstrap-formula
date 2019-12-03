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

# This second loop is used to find ASCS/ERS shared instances to share their data as it's needed to enable HA before the cluster is created
{% for shared_node in netweaver.nodes if host != shared_node.host and shared_node.sid == node.sid and shared_node.sap_instance.lower() in ['ascs', 'ers'] and ':' in shared_node.shared_disk_dev %}

{% set shared_instance = '{:0>2}'.format(shared_node.instance) %}
{% set shared_instance_name =  shared_node.sid~'_'~shared_instance %}

mount_{{ shared_node.sap_instance.lower() }}_{{ shared_instance_name }}:
  mount.mounted:
    - name: /usr/sap/{{ shared_node.sid.upper() }}/{{ shared_node.sap_instance.upper() }}{{ shared_instance }}
    - device: {{ shared_node.shared_disk_dev }}
    - fstype: {{ fstype }}
    - mkmnt: True
    - opts:
      - defaults

{% endfor %}


{% elif node.sap_instance.lower() in ['pas', 'aas'] %}

create_folder_{{ node.sap_instance.lower() }}_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/D{{ instance }}

{% endif %}
{% endfor %}
