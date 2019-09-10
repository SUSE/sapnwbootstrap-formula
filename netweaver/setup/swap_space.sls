{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% if netweaver.create_swap|default(true) %}
{% set swap_dir = netweaver.swap_config.directory|default('/var/lib/swap', true) %}
{% set swap_file = swap_dir~'/swapfile' %}
{% set swap_size = netweaver.swap_config.size|default(128, true) %}

create_swap_dir_{{ host }}:
  file.directory:
  - name: {{ swap_dir }}

create_swap_file_{{ host }}:
  cmd.run:
  - name: 'dd if=/dev/zero of={{ swap_file }} bs=1048576 count={{ swap_size }} && chmod 0600 {{ swap_file }}'
  - creates: {{ swap_file }}

set_swap_file_{{ host }}:
  cmd.wait:
  - name: 'mkswap {{ swap_file }}'
  - watch:
    - create_swap_file_{{ host }}

set_swap_file_status_{{ host }}:
  cmd.run:
  - name: 'swapon {{ swap_file }}'
  - unless: grep {{ swap_file }} /proc/swaps
  - require:
    - set_swap_file_{{ host }}

mount_swap_{{ host }}:
  mount.swap:
  - name : {{ swap_file }}
  - persist: True
  - require:
    - set_swap_file_{{ host }}

{% endif %}