{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if host == node.host %}

{% set swap_file = '/var/lib/swap/swapfile' %}

create_swap_dir:
  cmd.run:
  - name: mkdir -p /var/lib/swap

create_swap_file:
  cmd.run:
  - name: 'dd if=/dev/zero of={{ swap_file }} bs=1048576 count={{ grains["mem_total"] * 2 }} && chmod 0600 {{ swap_file }}'
  - creates: {{ swap_file }}

set_swap_file:
  cmd.wait:
  - name: 'mkswap {{ swap_file }}'
  - watch:
    - create_swap_file

set_swap_file_status:
  cmd.run:
  - name: 'swapon {{ swap_file }}'
  - unless: grep {{ swap_file }} /proc/swaps
  - require:
    - set_swap_file

{{ swap_file }}:
  mount.swap:
  - persist: True
  - require:
    - set_swap_file

{% endif %}
{% endfor %}
