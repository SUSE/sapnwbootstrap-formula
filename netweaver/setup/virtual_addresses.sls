{%- from "netweaver/map.jinja" import netweaver with context -%}

{% for ip_address, hostname in netweaver.virtual_addresses.items() %}
{{ hostname }}:
  host.present:
    - ip: {{ ip_address }}
    - names:
      - {{ hostname }}
{% endfor %}
