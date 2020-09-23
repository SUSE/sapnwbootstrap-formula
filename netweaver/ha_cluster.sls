{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if netweaver.ha_enabled and host == node.host and node.sap_instance in ['ascs', 'ers'] %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name = node.sid~'_'~instance %}
{% set instance_folder = node.sap_instance.upper()~instance %}
{% set profile_file = '/usr/sap/'~node.sid.upper()~'/SYS/profile/'~node.sid.upper()~'_'~instance_folder~'_'~node.virtual_host %}

install_suse_connetor:
  pkg.installed:
    - name: sap-suse-cluster-connector

wait_until_systems_installed:
  netweaver.check_instance_present:
{% if node.sap_instance.lower() == 'ascs' %}
    - name: ENQREP
{% else %}
    - name: MESSAGESERVER
{% endif %}
    - dispstatus: GREEN
    - sid: {{ node.sid.lower() }}
    - inst: {{ instance }}
    - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - retry:
        attempts: 20
        interval: 30

update_sapservices_{{ instance_name }}:
    netweaver.sapservices_updated:
      - name: {{ node.sap_instance.lower() }}
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}

stop_sap_instance_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'Stop'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2

stop_sap_instance_service_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'StopService'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2

add_ha_scripts_{{ instance_name }}:
  file.append:
    - name: {{ profile_file }}
    - text: |
        #-----------------------------------------------------------------------
        # HA script connector
        #-----------------------------------------------------------------------
        service/halib = $(DIR_CT_RUN)/saphascriptco.so
        service/halib_cluster_connector = /usr/bin/sap_suse_cluster_connector
    - unless:
      - cat {{ profile_file }} | grep '^service/halib'

add_sapuser_to_haclient_{{ instance_name }}:
  user.present:
    - name: {{ node.sid.lower() }}adm
    - remove_groups: False
    - groups:
      - haclient

{% if node.sap_instance.lower() == 'ascs' %}

adapt_sap_profile_ascs_{{ instance_name }}:
  file.replace:
    - name: {{ profile_file }}
    - pattern: '^Restart_Program_01 = local \$\(_EN\) pf=\$\(_PF\)'
    - repl: 'Start_Program_01 = local $(_EN) pf=$(_PF)'

set_keepalive_option_{{ instance_name }}:
  file.line:
    - name: {{ profile_file }}
    - mode: ensure
    - content: enque/encni/set_so_keepalive = true
    # onlyif statements can be improved when salt version 3000 is used
    # https://docs.saltstack.com/en/latest/ref/states/requisites.html#onlyif
    - onlyif: cat /etc/salt/grains | grep "ensa_version:.*1"

{% elif node.sap_instance.lower() == 'ers' %}

adapt_sap_profile_ers_{{ instance_name }}:
  file.replace:
    - name: {{ profile_file }}
    - pattern: '^Restart_Program_00 = local \$\(_ER\) pf=\$\(_PFL\) NR=\$\(SCSID\)'
    - repl: 'Start_Program_00 = local $(_ER) pf=$(_PFL) NR=$(SCSID)'

remove_autostart_option_{{ instance_name }}:
  file.line:
    - name: {{ profile_file }}
    - match: ^Autostart = 1.*$
    - mode: delete

{% endif %}

start_sap_instance_service_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'StartService {{ node.sid.upper() }}'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2

start_sap_instance_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'Start'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2

{% endfor %}
