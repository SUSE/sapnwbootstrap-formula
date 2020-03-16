{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}
{% for node in netweaver.nodes if node.host == host and (netweaver.sapcar_exe_file is defined and netweaver.swpm_sar_file and netweaver.swpm_extract_dir is defined) %}

extract_installer_file_{{ node.host }}:
    netweaver.installer_file_extracted:
    - sapcar_exe_file: {{ node.install.sapcar_exe_file }}
    - swpm_sar_file: {{ node.install.swpm_sar_file }}
    - swpm_extract_dir: {{ netweaver.swpm_extract_dir }}
    - options: -manifest SIGNATURE.SMF

{% endfor %}