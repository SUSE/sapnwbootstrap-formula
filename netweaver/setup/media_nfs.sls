{%- from "netweaver/map.jinja" import netweaver with context -%}

nfs-client:
  pkg.installed

mount_swpm:
  mount.mounted:
    - name: /swpm
    - device: {{ netweaver.swpm_media }}
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults
