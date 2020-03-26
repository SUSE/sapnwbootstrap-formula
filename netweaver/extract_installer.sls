{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

{% if netweaver.sapcar_exe_file is defined and netweaver.swpm_sar_file is defined %}

extract_installer_file:
    sapcar.extracted:
    - name: {{ netweaver.swpm_sar_file }}
    - sapcar_exe: {{ netweaver.sapcar_exe_file }}
    - output_dir: {{ netweaver.swpm_extract_dir }}
    - options: "-manifest SIGNATURE.SMF"

{% endif %}