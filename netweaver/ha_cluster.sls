{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% for node in netweaver.nodes if netweaver.ha_enabled and host == node.host and node.sap_instance in ['ascs', 'ers'] %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set instance_name = node.sid~'_'~instance %}
{% set instance_folder = node.sap_instance.upper()~instance %}
{% set profile_file = '/usr/sap/'~node.sid.upper()~'/SYS/profile/'~node.sid.upper()~'_'~instance_folder~'_'~node.virtual_host %}
{% set virtual_host_interface = node.virtual_host_interface|default('eth0') %}
{% set ifcfg_file = '/etc/sysconfig/network/ifcfg-'~virtual_host_interface %}

{% for virtual_ip, hostname in netweaver.virtual_addresses.items() if hostname == node.virtual_host %}
# Remove permanent ip address as the element is managed by the cluster
remove_permanent_ipaddr_{{ instance_name }}:
  file.line:
    - name: {{ ifcfg_file }}
    - match: {{ virtual_ip }}
    - mode: delete
{% endfor %}

install_suse_connector:
  pkg.installed:
    - name: sap-suse-cluster-connector
    - require:
      - netweaver_install_{{ instance_name }}

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
    - require:
      - netweaver_install_{{ instance_name }}

update_sapservices_{{ instance_name }}:
    netweaver.sapservices_updated:
      - name: {{ node.sap_instance.lower() }}
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
      - require:
        - netweaver_install_{{ instance_name }}

stop_sap_instance_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'Stop'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2
    - require:
      - netweaver_install_{{ instance_name }}

stop_sap_instance_service_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'StopService'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2
    - require:
      - netweaver_install_{{ instance_name }}

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
    - require:
      - stop_sap_instance_{{ instance_name }}

add_sapuser_to_haclient_{{ instance_name }}:
  user.present:
    - name: {{ node.sid.lower() }}adm
    - remove_groups: False
    - groups:
      - haclient
    - require:
      - stop_sap_instance_{{ instance_name }}

{% if node.sap_instance.lower() == 'ascs' %}

adapt_sap_profile_ascs_{{ instance_name }}:
  file.replace:
    - name: {{ profile_file }}
    - pattern: '^Restart_Program_01 = local \$\(_EN\) pf=\$\(_PF\)'
    - repl: 'Start_Program_01 = local $(_EN) pf=$(_PF)'
    - require:
      - stop_sap_instance_{{ instance_name }}

set_keepalive_option_{{ instance_name }}:
  file.line:
    - name: {{ profile_file }}
    - mode: insert
    - location: end
    - content: enque/encni/set_so_keepalive = true
    # onlyif statements can be improved when salt version 3000 is used
    # https://docs.saltstack.com/en/latest/ref/states/requisites.html#onlyif
    - onlyif: cat /etc/salt/grains | grep "ensa_version_{{ node.sid.lower() }}_{{ instance }}:.*1"
    - require:
      - stop_sap_instance_{{ instance_name }}

{% elif node.sap_instance.lower() == 'ers' %}

adapt_sap_profile_ers_{{ instance_name }}:
  file.replace:
    - name: {{ profile_file }}
    - pattern: '^Restart_Program_00 = local \$\(_ER\) pf=\$\(_PFL\) NR=\$\(SCSID\)'
    - repl: 'Start_Program_00 = local $(_ER) pf=$(_PFL) NR=$(SCSID)'
    - require:
      - stop_sap_instance_{{ instance_name }}

remove_autostart_option_{{ instance_name }}:
  file.line:
    - name: {{ profile_file }}
    - match: ^Autostart = 1.*$
    - mode: delete
    - require:
      - stop_sap_instance_{{ instance_name }}

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
    - require:
      - stop_sap_instance_{{ instance_name }}

start_sap_instance_{{ instance_name }}:
  module.run:
    - netweaver.execute_sapcontrol:
      - function: 'Start'
      - sid: {{ node.sid.lower() }}
      - inst: {{ instance }}
      - password: {{ netweaver.sid_adm_password|default(netweaver.master_password) }}
    - test.sleep:
      - length: 2
    - require:
      - stop_sap_instance_{{ instance_name }}

{% endfor %}
