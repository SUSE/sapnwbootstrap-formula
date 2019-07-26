{%- from "netweaver/map.jinja" import netweaver with context -%}

nfs-client:
  pkg.installed

mount_sapcd:
  mount.mounted:
    - name: /sapcd
    - device: {{ netweaver.sapcd_media }}
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults
