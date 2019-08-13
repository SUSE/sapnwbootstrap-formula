{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host and node.shared_disk_dev is defined %}

{% if node.init_shared_disk is defined and node.init_shared_disk == True %}

label_partition:
  module.run:
    - name: partition.mklabel
    - device: {{ node.shared_disk_dev }}
    - label_type: gpt

sbd_partition:
  module.run:
    - name: partition.mkpart
    - device: {{ node.shared_disk_dev }}
    - part_type: primary
    - start: 1049k
    - end: 8388k
    - require:
      - label_partition

first_partition:
  module.run:
    - name: partition.mkpart
    - device: {{ node.shared_disk_dev }}
    - part_type: primary
    - start: 8389k
    - end: 10.7G
    - require:
      - label_partition

second_partition:
  module.run:
    - name: partition.mkpart
    - device: {{ node.shared_disk_dev }}
    - part_type: primary
    - start: 10.7G
    - end: 21.5G
    - require:
      - label_partition

format_first_partition:
  module.run:
    - name: partition.mkfs
    - device: {{ node.shared_disk_dev }}2
    - fs_type: xfs
    - require:
      - first_partition

format_second_partition:
  module.run:
    - name: partition.mkfs
    - device: {{ node.shared_disk_dev }}3
    - fs_type: xfs
    - require:
      - second_partition

{% else %}

rescan_partition:
  cmd.run:
    - name: until [ $(partprobe; fdisk -l {{ node.shared_disk_dev }} | grep Device -A 15 | wc -l) -eq 4 ];do sleep 10;done
    - output_loglevel: quiet
    - hide_output: True
    - timeout: 6000

{% endif %}
{% endfor %}
