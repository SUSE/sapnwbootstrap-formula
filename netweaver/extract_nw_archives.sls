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
    - output_dir: {{ swpm_extract_dir }}
    - options: "-manifest SIGNATURE.SMF"

{% endif %}

{% set additional_dvd_folders = [] %}

{% for dvd_entry in netweaver.additional_dvds %}
{% set dvd = dvd_entry | string %}
{% set dvd_folder_name = salt['file.basename'](dvd.split('.')[0]) %}
{% set dvd_extract_dir = nw_extract_dir | path_join(dvd_folder_name) %}

{%- if dvd.endswith((".ZIP", ".zip", ".RAR", ".rar", ".exe", ".EXE")) %}
{% do additional_dvd_folders.append(dvd_extract_dir) %}
{%- else %}
{% do additional_dvd_folders.append(dvd) %}
{%- endif %}

{%- if dvd.endswith((".ZIP", ".zip", ".RAR", ".rar")) %}

extract_nw_archive_{{ dvd }}:
  archive.extracted:
    - name: {{ dvd_extract_dir }}
    - enforce_toplevel: False
    - source: {{ dvd }}

{%- elif dvd.endswith((".exe", ".EXE")) %}

{% if loop.first %}
{% set unrar_package = 'unrar_wrapper' if grains['osrelease_info'][0] == 15 else 'unrar' %}
install_unrar_package_to_extract__{{ dvd }}:
  pkg.installed:
    - name: {{ unrar_package }}
{%- endif %}

extract_nw_multipart_archive_{{ dvd }}:
  cmd.run:
    - name: unrar x {{ dvd }}
    - cwd: {{ dvd_extract_dir }}
    - require:
        - install_unrar_package

{%- endif %}
{%- endfor %}