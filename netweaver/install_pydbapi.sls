{%- from "netweaver/map.jinja" import netweaver with context -%}
{%- from "netweaver/extract_nw_archives.sls" import additional_dvd_folders with context -%}

{% set host = grains['host'] %}

{% for node in netweaver.nodes if node.host == host and node.sap_instance in ['db', 'pas', 'aas'] %}
{% if loop.first %}
{% set pydbapi_output_dir = '/tmp/pydbapi' %}
nw_install_python_pip:
  pkg.installed:
    {% if grains['pythonversion'][0] == 2 %}
    - name: python-pip
    {% else %}
    - name: python3-pip
    {% endif %}
    - retry:
        attempts: 3
        interval: 15
    - resolve_capabilities: true

nw_extract_pydbapi_client:
  hana.pydbapi_extracted:
    - name: PYDBAPI.TGZ
    - software_folders: {{ additional_dvd_folders }}
    - output_dir: {{ pydbapi_output_dir }}
    - hana_version: '20'
    - force: true

# pip.installed fails as it cannot manage propler file names with regular expressions
# TODO: Improve this to use pip.installed somehow
nw_install_pydbapi_client:
  cmd.run:
    {% if grains['pythonversion'][0] == 2 %}
    - name: /usr/bin/python -m pip install {{ pydbapi_output_dir }}/hdbcli-*.tar.gz
    {% else %}
    - name: /usr/bin/python3 -m pip install {{ pydbapi_output_dir }}/hdbcli-*.tar.gz
    {% endif %}
    - reload_modules: true
    - require:
      - nw_install_python_pip
      - nw_extract_pydbapi_client

nw_reload_hdb_connector:
  module.run:
    - hana.reload_hdb_connector:
    - require:
      - nw_install_pydbapi_client

nw_remove_pydbapi_client:
  file.absent:
    - name: {{ pydbapi_output_dir }}
    - onchanges:
      - nw_extract_pydbapi_client
{% endif %}
{% endfor %}
