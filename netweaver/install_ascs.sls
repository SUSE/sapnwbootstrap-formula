{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'ascs' %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

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
    - virtual_host_interface: {{ node.virtual_host_interface|default('eth1') }}
    - product_id: NW_ABAP_ASCS:NW750.HDB.ABAPHA
    - cwd: {{ netweaver.installation_folder }}
    - additional_dvds: {{ netweaver.additional_dvds }}
    - require:
      - create_ascs_inifile_{{ instance_name }}

remove_ascs_inifile_{{ instance_name }}:
  file.absent:
    - name: /tmp/ascs.inifile.params
    - require:
      - create_ascs_inifile_{{ instance_name }}

{% endfor %}
