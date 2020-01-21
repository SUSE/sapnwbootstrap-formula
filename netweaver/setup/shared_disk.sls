{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host and node.shared_disk_dev is defined and ':' not in node.shared_disk_dev %}

{% if node.init_shared_disk is defined and node.init_shared_disk == True %}

label_partition:
  cmd.run:
    - name: /usr/sbin/parted -s {{ node.shared_disk_dev }} mklabel gpt

sbd_partition:
  cmd.run:
    - name: /usr/sbin/parted -s {{ node.shared_disk_dev }} mkpart primary 1049k 8388k
    - require:
      - label_partition

first_partition:
  cmd.run:
    - name: /usr/sbin/parted -s {{ node.shared_disk_dev }} mkpart primary 8389k 10.7G
    - require:
      - label_partition

second_partition:
  cmd.run:
    - name: /usr/sbin/parted -s {{ node.shared_disk_dev }} mkpart primary 10.7G 21.5G
    - require:
      - label_partition

# This state is done to avoid failure in disk formatting
wait_until_partition:
  module.run:
    - test.sleep:
      - length: 5
    - require:
      - sbd_partition
      - first_partition
      - second_partition

format_first_partition:
  cmd.run:
    - name: /sbin/mkfs.xfs {{ node.shared_disk_dev }}2
    - require:
      - wait_until_partition
      - first_partition

format_second_partition:
  cmd.run:
    - name: /sbin/mkfs.xfs {{ node.shared_disk_dev }}3
    - require:
      - wait_until_partition
      - second_partition

{% else %}

rescan_partition:
  cmd.run:
    - name: until [ $(partprobe; fdisk -l {{ node.shared_disk_dev }} | grep Device -A 15 | wc -l) -eq 4 ];do sleep 10;done
    - output_loglevel: quiet
    - hide_output: True
    - timeout: 6000

# This state is done to give always time to the disk formatting done by the 1st node
wait_until_rescan:
  module.run:
    - test.sleep:
      - length: 10
    - require:
      - rescan_partition

rescan_after_formatting:
  cmd.run:
    - name: partprobe; fdisk -l {{ node.shared_disk_dev }}
    - output_loglevel: quiet
    - hide_output: True
    - timeout: 6000
    - require:
      - wait_until_rescan

{% endif %}
{% endfor %}
