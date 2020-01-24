{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance == 'ers' %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name =  node.sid~'_'~instance %}

create_ers_inifile_{{ instance_name }}:
  file.managed:
    - source: salt://netweaver/templates/ers.inifile.params.j2
    - name: /tmp/ers.inifile.params
    - template: jinja
    - context: # set up context for template ers.inifile.params.j2
        master_password: {{ netweaver.master_password }}
        sap_adm_password: {{ netweaver.sap_adm_password|default(netweaver.master_password) }}
        sid_adm_password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
        sid: {{ node.sid }}
        instance: {{ instance }}
        virtual_hostname: {{ node.virtual_host }}
        download_basket: {{ netweaver.sapexe_folder }}

check_sapprofile_directory_exists_{{ instance_name }}:
  file.exists:
    - name: /sapmnt/{{ node.sid.upper() }}/profile
    - retry:
        attempts: 70
        interval: 30

netweaver_install_{{ instance_name }}:
  netweaver.installed:
    - name: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - software_path: {{ netweaver.swpm_folder }}
    - root_user: {{ node.root_user }}
    - root_password: {{ node.root_password }}
    - config_file: /tmp/ers.inifile.params
    - virtual_host: {{ node.virtual_host }}
    - virtual_host_interface: {{ node.virtual_host_interface|default('eth0') }}
    - virtual_host_mask: {{ node.virtual_host_mask|default(24) }}
    - product_id: NW_ERS:NW750.HDB.ABAPHA
    - cwd: {{ netweaver.installation_folder }}
    - additional_dvds: {{ netweaver.additional_dvds }}
    - ascs_password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - timeout: 1500
    - interval: 15
    - require:
      - create_ers_inifile_{{ instance_name }}
      - check_sapprofile_directory_exists_{{ instance_name }}

remove_ers_inifile_{{ instance_name }}:
  file.absent:
    - name: /tmp/ers.inifile.params
    - require:
      - create_ers_inifile_{{ instance_name }}

{% endfor %}
