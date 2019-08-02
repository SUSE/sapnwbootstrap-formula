#required packages to install SAP Netweaver

{% set pattern_available = 1 %}
{% if grains['os_family'] == 'Suse' %}
{% set pattern_available = salt['cmd.retcode']('zypper search patterns-sap-nw') %}
{% endif %}

{% if pattern_available == 0 %}
{% set repo = salt['pkg.info_available']('patterns-sap-nw')['patterns-sap-nw']['repository'] %}
install_patterns_sap_netweaver:
  pkg.installed:
    - name: patterns-sap-nw
    - fromrepo: {{ repo }}
    - retry:
        attempts: 3
        interval: 15

{% else %}

install_netweaver_packages:
  pkg.installed:
    - retry:
        attempts: 3
        interval: 15
    - pkgs:
      - tcsh

{% endif %}

# Install shaptools depending on the os and python version
install_netweaver_shaptools:
  pkg.installed:
    {% if grains['pythonversion'][0] == 2 %}
    - name: python-shaptools
    {% else %}
    - name: python3-shaptools
    {% endif %}
    - retry:
        attempts: 3
        interval: 15
    - resolve_capabilities: true
