{%- from "netweaver/map.jinja" import netweaver with context -%}

nfs-client:
  pkg.installed:
    - retry:
        attempts: 3
        interval: 15

mount_swpm:
  mount.mounted:
    - name: /swpm
    - device: {{ netweaver.swpm_media }}
    - fstype: nfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults
