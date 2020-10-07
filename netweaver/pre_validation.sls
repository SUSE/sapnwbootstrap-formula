{% from "netweaver/map.jinja" import netweaver with context -%}

{% set host = grains['host'] %}

{# Check for SWPM archive media checkbox #}
{% if netweaver.use_swpm_sar_file is defined and netweaver.use_swpm_sar_file == false %}
    {% do netweaver.pop('swpm_sar_file', none) %}
{% endif %}

{% for node in netweaver.nodes if node.host == host %}

    {# Check netweaver extra parameters #}
    {% if node.extra_parameters is defined and node.extra_parameters|length > 0 and node.extra_parameters is not mapping %}
      {% set new_extra_parameters = {} %}
      {% for new_item in node.extra_parameters %}
        {% do new_extra_parameters.update({new_item.key:  new_item.value}) %}
      {% endfor %}
      {% do node.update({'extra_parameters': new_extra_parameters}) %}
    {% endif %}

{% endfor %}
