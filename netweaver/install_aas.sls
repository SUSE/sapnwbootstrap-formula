{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'aas' %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

create_aas_inifile_{{ instance_name }}:
  file.managed:
    - source: salt://netweaver/templates/aas.inifile.params.j2
    - name: /tmp/aas.inifile.params
    - template: jinja
    - context: # set up context for template aas.inifile.params.j2
        master_password: {{ node.master_password }}
        sid: {{ node.sid }}
        instance: {{ instance }}
        virtual_hostname: {{ node.virtual_host }}
        download_basket: /swpm/{{ netweaver.sapexe_folder }}
        schema_name: {{ netweaver.schema_password|default('SAPABAP1') }}
        schema_password: {{ netweaver.schema_password }}
        hana_password: {{ netweaver.hana.password }}
        hana_inst: {{ netweaver.hana.instance }}

netweaver_install_{{ instance_name }}:
  netweaver.installed:
    - name: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ node.master_password }}
    - software_path: /swpm/{{ netweaver.swpm_folder }}
    - root_user: {{ node.root_user }}
    - root_password: {{ node.root_password }}
    - config_file: /tmp/aas.inifile.params
    - virtual_host: {{ node.virtual_host }}
    - virtual_host_interface: {{ node.virtual_host_interface|default('eth1') }}
    - product_id: NW_DI:NW750.HDB.ABAPHA
    - cwd: {{ netweaver.installation_folder }}
    - additional_dvds: {{ netweaver.additional_dvds }}
    - require:
      - create_aas_inifile_{{ instance_name }}
    - retry:
        attempts: {{ node.attempts|default(30) }}
        interval: 120

remove_aas_inifile_{{ instance_name }}:
  file.absent:
    - name: /tmp/aas.inifile.params
    - require:
      - create_aas_inifile_{{ instance_name }}

{% endfor %}
