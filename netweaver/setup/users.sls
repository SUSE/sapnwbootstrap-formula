{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% if netweaver.sidadm_user is defined %}
{% for node in netweaver.nodes if host == node.host %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sap_instance.lower()~'_'~node.sid~'_'~instance %}

create_sapsys_group_{{ instance_name }}:
  group.present:
    - name: sapsys
    - gid: {{ netweaver.sidadm_user.gid }}

create_sidadm_user_{{ instance_name }}:
  user.present:
    - name: {{ node.sid.lower() }}adm
    - fullname: SAP System Administrator
    - shell: /bin/csh
    - home: /home/{{ node.sid.lower() }}adm
    - uid: {{ netweaver.sidadm_user.uid }}
    - gid: {{ netweaver.sidadm_user.gid }}
    - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - hash_password: True
    - groups:
      - sapsys

{% if node.sap_instance.lower() in ['ascs', 'ers', 'pas', 'aas'] %}
create_sid_folder_{{ instance_name }}:
  file.directory:
    - name: /usr/sap/{{ node.sid.upper() }}
    - user: {{ node.sid.lower() }}adm
    - group: sapsys
    - mode: 755
    - recurse:
      - user
      - group
      - mode
{% endif %}

{% endfor %}
{% endif %}
