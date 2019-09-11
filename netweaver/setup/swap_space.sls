{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% if netweaver.create_swap|default(true) %}
# Set default values incase when no swap configuration is provided
{% if netweaver.swap_config is not defined %}
{% set swap_dir = '/var/lib/swap' %}
{% set swap_size = 2048 %}
# Case when partial or all of swap configuration is provided
{% else %}
{% set swap_dir = netweaver.swap_config.directory|default('/var/lib/swap', true) %}
{% set swap_size = netweaver.swap_config.size|default(2048, true) %}
{% endif %}

{% set swap_file = swap_dir~'/swapfile' %}

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