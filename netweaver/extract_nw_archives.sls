{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set nw_extract_dir = netweaver.nw_extract_dir %}
{% set swpm_extract_dir = nw_extract_dir| path_join('SWPM') %}

setup_nw_extract_directory:
  file.directory:
    - name: {{ nw_extract_dir }}
    - mode: 755
    - makedirs: True

{% if netweaver.sapcar_exe_file is defined and netweaver.swpm_sar_file is defined %}

extract_installer_file:
    sapcar.extracted:
    - name: {{ netweaver.swpm_sar_file }}
    - sapcar_exe: {{ netweaver.sapcar_exe_file }}
    - output_dir: {{ nw_extract_dir }}/SWPM
    - options: "-manifest SIGNATURE.SMF"

{% endif %}

{% set additional_dvd_folders = [] %}

{% for dvd in netweaver.additional_dvds %}
{% set dvd_folder = salt['file.basename'](dvd.split('.')[0]) %}
{% do additional_dvd_folders.append(nw_extract_dir | path_join(dvd_folder)) %}

{%- if dvd.endswith((".ZIP", ".zip", ".RAR", ".rar")) %}

extract_nw_archive:
  archive.extracted:
    - name: {{ nw_extract_dir | path_join(dvd_folder) }}
    - enforce_toplevel: False
    - source: {{ dvd }}

{%- elif dvd.endswith((".exe", ".EXE")) %}

{% set unrar_package = 'unrar_wrapper' if grains['osrelease_info'][0] == 15 else 'unrar' %}
install_unrar_package:
  pkg.installed:
    - name: {{ unrar_package }}

extract_nw_multipart_archive:
  cmd.run:
    - name: unrar x {{ dvd }}
    - cwd: {{ nw_extract_dir | path_join(dvd_folder) }}
    - require:
        - install_unrar_package

{%- endif %}
{%- endfor %}