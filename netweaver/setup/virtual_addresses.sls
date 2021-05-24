{%- from "netweaver/map.jinja" import netweaver with context -%}
{%- set host = grains['host'] %}
# Hack to get empty dictionary on SUMA
{%- set virtual_addresses = salt['pillar.get']('netweaver:virtual_addresses', {}) or {} %}

{% for ip_address, hostname in virtual_addresses.items() %}
{{ hostname }}:
  host.present:
    - ip: {{ ip_address }}
    - names:
      - {{ hostname }}
{% endfor %}


{% for node in netweaver.nodes if node.host == host %}
# Set the virtual ip addresses permanently
{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name = node.sid~'_'~instance %}
{% set virtual_host_interface = node.virtual_host_interface|default('eth0') %}
{% set ifcfg_file = '/etc/sysconfig/network/ifcfg-'~virtual_host_interface %}
{% set iddr_count = salt['cmd.run']('cat '~ifcfg_file~' | grep -c ^IPADDR || true', python_shell=true)|int %}

{% if loop.first %}
add_start_mode_{{ virtual_host_interface }}:
  file.append:
    - name: {{ ifcfg_file }}
    - text: STARTMODE=onboot
    - unless:
      - cat {{ ifcfg_file }} | grep '^STARTMODE='

add_boot_proto_{{ virtual_host_interface }}:
  file.append:
    - name: {{ ifcfg_file }}
    - text: BOOTPROTO=static
    - unless:
      - cat {{ ifcfg_file }} | grep '^BOOTPROTO='
{% endif %}

{% set current_iddr = loop.index0+iddr_count %}
{% for virtual_ip, hostname in virtual_addresses.items() if hostname == node.virtual_host %}
add_ipaddr_{{ virtual_host_interface }}_{{ instance_name }}:
  file.append:
    - name: {{ ifcfg_file }}
    - text: IPADDR_{{ current_iddr }}={{ virtual_ip }}/{{ node.virtual_host_mask|default(24) }}
    - unless:
      - cat {{ ifcfg_file }} | grep '{{ virtual_ip }}'
{% endfor %}

{% endfor %}
