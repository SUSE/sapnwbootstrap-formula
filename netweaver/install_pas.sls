{%- from "netweaver/map.jinja" import netweaver with context -%}
{%- from "netweaver/extract_nw_archives.sls" import additional_dvd_folders with context -%}
{%- from "netweaver/extract_nw_archives.sls" import swpm_extract_dir with context -%}

{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'pas' %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set hana_instance = '{:0>2}'.format(netweaver.hana.instance) %}
{% set instance_name = node.sid~'_'~instance %}

{% set product_id = node.product_id|default(netweaver.product_id) %}
{% set product_id = 'NW_ABAP_CI:'~product_id if 'NW_ABAP_CI' not in product_id else product_id %}
{% set inifile = '/tmp/pas.inifile'~instance_name~'.params' %}

create_pas_inifile_{{ instance_name }}:
  file.managed:
    - source: salt://netweaver/templates/pas.inifile.params.j2
    - name: {{ inifile }}
    - template: jinja
    - context: # set up context for template pas.inifile.params.j2
        master_password: {{ netweaver.master_password }}
        sap_adm_password: {{ netweaver.sap_adm_password|default(netweaver.master_password) }}
        sid_adm_password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
        sid: {{ node.sid }}
        instance: {{ instance }}
        virtual_hostname: {{ node.virtual_host }}
        download_basket: {{ netweaver.sapexe_folder }}
        schema_name: {{ netweaver.schema.name|default('SAPABAP1') }}
        schema_password: {{ netweaver.schema.password }}
        ascs_virtual_hostname: {{ node.ascs_virtual_host }}
        hana_host: {{ netweaver.hana.host }}
        hana_sid: {{ netweaver.hana.sid }}
        hana_password: {{ netweaver.hana.password }}
        hana_inst: {{ hana_instance }}
        sapmnt_path: {{ netweaver.sapmnt_path }}

{% if node.extra_parameters is defined %}
update_pas_inifile_{{ instance_name }}:
  module.run:
    - netweaver.update_conf_file:
      - conf_file: {{ inifile }}
      - {%- for key,value in node.extra_parameters.items() %}
        {{ key }}: "{{ value|string }}"
        {%- endfor %}
{% endif %}

check_sapprofile_directory_exists_{{ instance_name }}:
  file.exists:
    - name: {{ netweaver.sapmnt_path }}/{{ node.sid.upper() }}/profile
    - retry:
        attempts: 70
        interval: 30

wait_for_db_{{ instance_name }}:
  hana.available:
    - name: {{ netweaver.hana.host }}
    - port: 3{{ hana_instance }}15
    - user: {{ netweaver.schema.name|default('SAPABAP1') }}
    - password: {{ netweaver.schema.password }}
    - timeout: 5000
    - interval: 30
    - require:
      - check_sapprofile_directory_exists_{{ instance_name }}
      - nw_install_pydbapi_client

netweaver_install_{{ instance_name }}:
  netweaver.installed:
    - name: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - software_path: {{ netweaver.swpm_folder|default(swpm_extract_dir) }}
    - root_user: {{ node.root_user }}
    - root_password: {{ node.root_password }}
    - config_file: {{ inifile }}
    - virtual_host: {{ node.virtual_host }}
    - virtual_host_interface: {{ node.virtual_host_interface|default('eth0') }}
    - virtual_host_mask: {{ node.virtual_host_mask|default(24) }}
    - product_id: {{ product_id }}
    - cwd: {{ netweaver.installation_folder }}
    - additional_dvds: {{ additional_dvd_folders }}
    - require:
      - create_pas_inifile_{{ instance_name }}
      - wait_for_db_{{ instance_name }}
    - retry:
        attempts: {{ node.attempts|default(10) }}
        interval: {{ node.interval|default(600) }}

remove_pas_inifile_{{ instance_name }}:
  file.absent:
    - name: {{ inifile }}
    - require:
      - create_pas_inifile_{{ instance_name }}

{% endfor %}
