/*Copyright (C) 2022 Dremio Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.*/

{% macro config_cols(label, default_cols=none) %}
  {%- set cols = config.get(label | replace(" ", "_"), validator=validation.any[list, basestring]) or default_cols -%}
  {%- if cols is not none %}
    {%- if cols is string -%}
      {%- set cols = [cols] -%}
    {%- endif -%}
    {{ label }} (
    {{ cols | join(', ') }}
    )
  {%- endif %}
{%- endmacro -%}

{% macro partition_method() %}
  {%- set method = config.get('partition_method', validator=validation.any[basestring]) -%}
  {%- if method is not none -%}
   {{ method }}
  {%- endif %}
{%- endmacro -%}

{%- macro join_using(left_table, right_table, left_columns, right_columns=none) -%}
  {%- for column_name in left_columns -%}
    {{ left_table }}.{{ column_name }} = {{ right_table }}.{{ right_columns[loop.index0] if right_columns else column_name }}
    {% if not loop.last %} and {% endif -%}
  {%- endfor -%}
{%- endmacro -%}
