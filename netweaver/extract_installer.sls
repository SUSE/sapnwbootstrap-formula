{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}
{% for node in netweaver.nodes if node.host == host and (netweaver.sapcar_exe_file is defined and netweaver.swpm_sar_file and netweaver.swpm_extract_dir is defined) %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set name = '{}_{}'.format(node.sid, instance) %}


validate_sapcar_permission_{{ host }}_{{ name }}:
    file.managed:
    - name: {{ netweaver.sapcar_exe_file }}
    - mode: 644

extract_installer_file_{{ host }}_{{ name }}:
    sapcar.extracted:
    - name: {{ netweaver.swpm_sar_file }}
    - sapcar_exe: {{ netweaver.sapcar_exe_file }}
    - output_dir: {{ netweaver.swpm_extract_dir }}
    - options: "-manifest SIGNATURE.SMF"
    - require:
      - validate_sapcar_permission_{{ host }}_{{ name }}

{% endfor %}