{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set nw_extract_dir = netweaver.nw_extract_dir %}
{% set swpm_extract_dir = nw_extract_dir| path_join('SWPM') %}

setup_nw_extract_directory:
  file.directory:
    - name: {{ nw_extract_dir }}
    - mode: 755
    - makedirs: True

{# Install unrar tool needed for extracting multipart archives, based on SLES version #}
{% set unrar_package = 'unrar_wrapper' if grains['osrelease_info'][0] == 15 else 'unrar' %}
install_unrar_package:
  pkg.installed:
    - name: {{ unrar_package }}

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

{# Set the extraction path for various archives in dvds list based on the dvd extension name #}
{% set dvd = dvd_entry | string %}
{% set dvd_folder_name = salt['file.basename'](dvd.split('.')[0]) %}
{% set dvd_extract_dir = nw_extract_dir | path_join(dvd_folder_name) %}

{# Conditions to extract archives based on extension name #}
{%- if dvd.endswith((".ZIP", ".zip", ".RAR", ".rar")) %}

extract_nw_archive_{{ dvd }}:
  archive.extracted:
    - name: {{ dvd_extract_dir }}
    - enforce_toplevel: False
    - source: {{ dvd }}

{% do additional_dvd_folders.append(dvd_extract_dir) %}

{%- elif dvd.endswith((".exe", ".EXE")) %}

extract_nw_multipart_archive_{{ dvd }}:
  cmd.run:
    - name: unrar x {{ dvd }}
    - cwd: {{ nw_extract_dir }}
    - require:
        - install_unrar_package
{# As temporary workaround, the extraction path for multpart archive is calculated from archive name #}
{# TODO: Find better solution to set or detect the correct extraction path when extracting multipart rar archive #}
{% set exe_dvd_extract_dir = nw_extract_dir | path_join(dvd_folder_name.split('_')[0]) %}
{% do additional_dvd_folders.append(exe_dvd_extract_dir) %}

{%- elif dvd.endswith((".sar", ".SAR")) and netweaver.sapcar_exe_file is defined  %}

extract_sar_archive_{{ dvd }}:
    sapcar.extracted:
    - name: {{ dvd }}
    - sapcar_exe: {{ netweaver.sapcar_exe_file }}
    - output_dir: {{ dvd_extract_dir }}
    - options: "-manifest SIGNATURE.SMF"

{% do additional_dvd_folders.append(dvd_extract_dir) %}

{%- else %}
{% do additional_dvd_folders.append(dvd) %}

{%- endif %}
{%- endfor %}