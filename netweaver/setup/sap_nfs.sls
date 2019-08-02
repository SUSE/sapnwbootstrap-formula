{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

mount_sapmnt:
  mount.mounted:
    - name: /sapmnt
    - device: {{ netweaver.sapmnt_inst_media }}/sapmnt
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults

{% for node in netweaver.nodes if host == node.host %}

mount_usersapsys:
  mount.mounted:
    - name: /usr/sap/{{ node.sid.upper() }}/SYS
    - device: {{ netweaver.sapmnt_inst_media }}/usrsapsys
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults

{% endfor %}
