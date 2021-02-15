{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

# Provided sapmnt_inst_media is a NFS share path
{% if ':' in netweaver.sapmnt_inst_media %}

{% if loop.first %}
mount_sapmnt:
  mount.mounted:
    - name: {{ netweaver.sapmnt_path }}
    - device: {{ netweaver.sapmnt_inst_media }}/sapmnt
    - fstype: {{ netweaver.nfs_version }}
    - opts:
      - {{ netweaver.nfs_options }}
    - mkmnt: True
    - persist: True
{% endif %}

mount_usersapsys_{{ instance_name }}:
  mount.mounted:
    - name: /usr/sap/{{ node.sid.upper() }}/SYS
    - device: {{ netweaver.sapmnt_inst_media }}/usrsapsys
    - fstype: {{ netweaver.nfs_version }}
    - opts:
      - {{ netweaver.nfs_options }}
    - mkmnt: True
    - persist: True

{% if netweaver.clean_nfs and node.sap_instance == 'ascs' %}
clean_nfs_sapmnt_{{ instance_name }}:
  file.absent:
    - name: {{ netweaver.sapmnt_path }}/{{ node.sid.upper() }}

clean_nfs_usr_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/SYS
    - clean: True
{% endif %}

# Create the `/sapmnt` and `/usr/sap/{sid}/SYS` locally
{% else %}
{% if loop.first %}
create_folder_sapmnt:
  file.directory:
    - name: {{ netweaver.sapmnt_path }}
    - makedirs: True
{% endif %}

create_folder_sap_sys_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}/SYS
    - makedirs: True

{% endif %}
{% endfor %}
