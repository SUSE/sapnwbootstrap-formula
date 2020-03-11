{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'ascs' %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name = node.sid~'_'~instance %}

{% set product_id = node.product_id|default(netweaver.product_id) %}
{% set product_id = 'NW_ABAP_ASCS:'~product_id if 'NW_ABAP_ASCS' not in product_id else product_id %}
{% set inifile = '/tmp/ascs.inifile'~instance_name~'.params' %}

create_ascs_inifile_{{ instance_name }}:
  file.managed:
    - source: salt://netweaver/templates/ascs.inifile.params.j2
    - name: {{ inifile }}
    - template: jinja
    - context: # set up context for template ascs.inifile.params.j2
        master_password: {{ netweaver.master_password }}
        sap_adm_password: {{ netweaver.sap_adm_password|default(netweaver.master_password) }}
        sid_adm_password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
        sid: {{ node.sid }}
        instance: {{ instance }}
        virtual_hostname: {{ node.virtual_host }}
        download_basket: {{ netweaver.sapexe_folder }}

{% if node.extra_parameters is defined %}
update_ascs_inifile_{{ instance_name }}:
  module.run:
    - netweaver.update_conf_file:
      - conf_file: {{ inifile }}
      - {%- for key,value in node.extra_parameters.items() %}
        {{ key }}: "{{ value|string }}"
        {%- endfor %}
{% endif %}

netweaver_install_{{ instance_name }}:
  netweaver.installed:
    - name: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - software_path: {{ netweaver.swpm_folder }}
    - root_user: {{ node.root_user }}
    - root_password: {{ node.root_password }}
    - config_file: {{ inifile }}
    - virtual_host: {{ node.virtual_host }}
    - virtual_host_interface: {{ node.virtual_host_interface|default('eth0') }}
    - virtual_host_mask: {{ node.virtual_host_mask|default(24) }}
    - product_id: {{ product_id }}
    - cwd: {{ netweaver.installation_folder }}
    - additional_dvds: {{ netweaver.additional_dvds }}
    - require:
      - create_ascs_inifile_{{ instance_name }}

remove_ascs_inifile_{{ instance_name }}:
  file.absent:
    - name: {{ inifile }}
    - require:
      - create_ascs_inifile_{{ instance_name }}

{% endfor %}
