{%- from "netweaver/map.jinja" import netweaver with context -%}

# Based on https://launchpad.support.sap.com/#/notes/1410736
# And https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/high-availability-guide-suse#2d6008b0-685d-426c-b59e-6cd281fd45d7

{% for sysctl_key, sysctl_value in netweaver.sysctl_values.items()  %}

{{ sysctl_key }}:
  sysctl.present:
    - value: {{ sysctl_value }}

{% endfor %}
