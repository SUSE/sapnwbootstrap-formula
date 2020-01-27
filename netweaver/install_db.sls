{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'db' %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set hana_instance = '{:0>2}'.format(netweaver.hana.instance) %}
{% set instance_name = node.sid~'_'~instance %}

{% set product_id = node.product_id|default(netweaver.product_id) %}
{% set product_id = 'NW_ABAP_DB:'~product_id if 'NW_ABAP_DB' not in product_id else product_id %}

create_db_inifile_{{ instance_name }}:
  file.managed:
    - source: salt://netweaver/templates/db.inifile.params.j2
    - name: /tmp/db.inifile.params
    - template: jinja
    - context: # set up context for template db.inifile.params.j2
        master_password: {{ netweaver.master_password }}
        sap_adm_password: {{ netweaver.sap_adm_password|default(netweaver.master_password) }}
        sid_adm_password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
        sid: {{ node.sid }}
        download_basket: {{ netweaver.sapexe_folder }}
        schema_name: {{ netweaver.schema.name|default('SAPABAP1') }}
        schema_password: {{ netweaver.schema.password }}
        hana_host: {{ netweaver.hana.host }}
        hana_sid: {{ netweaver.hana.sid }}
        hana_password: {{ netweaver.hana.password }}
        hana_inst: {{ hana_instance }}

check_sapprofile_directory_exists_{{ instance_name }}:
  file.exists:
    - name: /sapmnt/{{ node.sid.upper() }}/profile
    - retry:
        attempts: 70
        interval: 30

wait_for_hana_{{ instance_name }}:
  hana.available:
    - name: {{ netweaver.hana.host }}
    - port: 3{{ hana_instance }}15
    - user: SYSTEM
    - password: {{ netweaver.hana.password }}
    - timeout: 5000
    - interval: 30
    - require:
      - check_sapprofile_directory_exists_{{ instance_name }}

netweaver_install_{{ instance_name }}:
  netweaver.db_installed:
    - name: {{ netweaver.hana.host }}
    - port: 3{{ hana_instance }}15
    - schema_name: {{ netweaver.schema.name|default('SAPABAP1') }}
    - schema_password: {{ netweaver.schema.password }}
    - software_path: {{ netweaver.swpm_folder }}
    - root_user: {{ node.root_user }}
    - root_password: {{ node.root_password }}
    - config_file: /tmp/db.inifile.params
    - virtual_host: {{ node.virtual_host }}
    - virtual_host_interface: {{ node.virtual_host_interface|default('eth0') }}
    - virtual_host_mask: {{ node.virtual_host_mask|default(24) }}
    - product_id: {{ product_id }}
    - cwd: {{ netweaver.installation_folder }}
    - additional_dvds: {{ netweaver.additional_dvds }}
    - require:
      - create_db_inifile_{{ instance_name }}
      - wait_for_hana_{{ instance_name }}
    - retry:
        attempts: {{ node.attempts|default(5) }}
        interval: 60

remove_db_inifile_{{ instance_name }}:
  file.absent:
    - name: /tmp/db.inifile.params
    - require:
      - create_db_inifile_{{ instance_name }}

{% endfor %}
