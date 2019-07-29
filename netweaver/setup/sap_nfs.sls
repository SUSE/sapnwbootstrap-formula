{%- from "netweaver/map.jinja" import netweaver with context -%}

mount_sapmnt:
  mount.mounted:
    - name: /sapmnt
    - device: {{ netweaver.sapmnt_inst_media }}/sapmnt
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults

mount_usersapsys:
  mount.mounted:
    - name: /usr/sap/{{ netweaver.sid.upper() }}/SYS
    - device: {{ netweaver.sapmnt_inst_media }}/usrsapsys
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults
