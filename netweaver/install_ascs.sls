{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'ascs' %}

{% set virtual_ip = salt.hosts.get_ip(node.virtual_host) %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

{#
# This block is not supported in SUSE distros yet
enable_virtual_address_{{ instance_name }}:
  network.managed:
    - name: {{ node.virtual_host_interface|default('eth1') }}
    - enabled: True
    - type: eth
    - proto: static
    - ipaddr: {{ virtual_ip }}
    - netmask: 255.255.255.0
#}

enable_virtual_address_{{ instance_name }}:
  cmd.run:
    - name: ip address add {{ virtual_ip }}/24 dev {{ node.virtual_host_interface|default('eth1') }}
    - unless: ip a | grep {{ virtual_ip }}/24

create_ascs_inifile_{{ instance_name }}:
  file.managed:
    - source: salt://netweaver/templates/ascs.inifile.params.j2
    - name: /tmp/ascs.inifile.params
    - template: jinja
    - context: # set up context for template ascs.inifile.params.j2
        master_password: {{ node.master_password }}
        sid: {{ node.sid }}
        instance: {{ instance }}
        virtual_hostname: {{ node.virtual_host }}
        download_basket: /swpm/{{ netweaver.sapexe_folder }}

netweaver_install_{{ instance_name }}:
  netweaver.installed:
    - name: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ node.master_password }}
    - software_path: /swpm/{{ netweaver.swpm_folder }}
    - root_user: {{ node.root_user }}
    - root_password: {{ node.root_password }}
    - config_file: /tmp/ascs.inifile.params
    - virtual_host: {{ node.virtual_host }}
    - product_id: NW_ABAP_ASCS:NW750.HDB.ABAPHA
    - require:
      - create_ascs_inifile_{{ instance_name }}
      - enable_virtual_address_{{ instance_name }}

remove_ascs_inifile_{{ instance_name }}:
  file.absent:
    - name: /tmp/ascs.inifile.params
    - require:
      - create_ascs_inifile_{{ instance_name }}

{% endfor %}
