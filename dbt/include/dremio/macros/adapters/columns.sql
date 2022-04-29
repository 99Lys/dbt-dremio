{% macro dremio__get_columns_in_relation(relation) -%}

  {%- set database = relation.database.strip('"') -%}
  {%- set schema = relation.schema.strip('"') -%}
  {%- set identifier = relation.identifier.strip('"') -%}
  {%- set schema_name = database
        + (('.' + schema) if schema != 'no_schema' else '') -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
    select column_name as column_name
        ,lower(data_type) as data_type
        ,character_maximum_length
        ,numeric_precision
        ,numeric_scale
    from information_schema.columns
    where table_schema = '{{ schema_name }}'
    and table_name = '{{ identifier }}'
    order by ordinal_position
  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}

{% endmacro %}

{% macro dremio__alter_column_type(relation, column_name, new_column_type) -%}

  {% call statement('alter_column_type') %}
    alter table {{ relation }} alter column {{ adapter.quote(column_name) }} {{ adapter.quote(column_name) }} {{ new_column_type }}
  {% endcall %}

{% endmacro %}

{% macro dremio__alter_relation_add_remove_columns(relation, add_columns, remove_columns) %}

  {% if add_columns is none %}
    {% set add_columns = [] %}
  {% endif %}
  {% if remove_columns is none %}
    {% set remove_columns = [] %}
  {% endif %}

  {% if add_columns | length > 0 %}
    {% set sql -%}
       alter {{ relation.type }} {{ relation }} add columns (

              {% for column in add_columns %}
                 {{ column.name }} {{ column.data_type }}{{ ',' if not loop.last }}
              {% endfor %}
        )
    {%- endset -%}
    {% do run_query(sql) %}
  {% endif %}

  {% if remove_columns | length > 0 %}
    {% for column in remove_columns %}
      {% set sql -%}
         alter {{ relation.type }} {{ relation }} drop column {{ column.name }}
      {%- endset -%}
      {% do run_query(sql) %}
    {% endfor %}
  {% endif %}

{% endmacro %}

{% macro intersect_columns(source_columns, target_columns) %}

  {% set result = [] %}
  {% set target_names = target_columns | map(attribute = 'column') | list %}

   {# --check whether the name attribute exists in the target - this does not perform a data type check #}
   {% for sc in source_columns %}
     {% if sc.name in target_names %}
        {{ result.append(sc) }}
     {% endif %}
   {% endfor %}

  {{ return(result) }}

{% endmacro %}

{% macro get_quoted_csv(column_names) %}

    {% set quoted = [] %}
    {% for col in column_names -%}
        {%- do quoted.append(adapter.quote(col)) -%}
    {%- endfor %}

    {%- set dest_cols_csv = quoted | join(', ') -%}
    {{ return(dest_cols_csv) }}

{% endmacro %}

{% macro diff_columns(source_columns, target_columns) %}

  {% set result = [] %}
  {% set target_names = target_columns | map(attribute = 'column') | list %}

   {# --check whether the name attribute exists in the target - this does not perform a data type check #}
   {% for sc in source_columns %}
     {% if sc.name not in target_names %}
        {{ result.append(sc) }}
     {% endif %}
   {% endfor %}

  {{ return(result) }}

{% endmacro %}

{%- macro get_quoted_csv_source_columns(source_name, table_name) -%}
  {%- if execute -%}
    {%- set source = graph.sources.values() | selectattr("source_name", "equalto", source_name) | selectattr("name", "equalto", table_name) | list | first -%}
    {# Got a hard time finding the following line !!! #}
    {%- for col_name, column in source.columns.items() -%}
      {%- if column.name in source.external.date_columns -%}
        {%- set date_format = source.external.date_format if source.external.date_format is defined else 'YYYY-MM-DD' -%}
        to_date(nullif(btrim({{ adapter.quote(column.name) }}), ''), '{{ date_format }}')
      {%- elif column.name in source.external.decimal_columns -%}
        {%- set decimal_separator = source.external.decimal_separator if source.external.decimal_separator is defined else ',' -%}
        {%- set decimals = source.external.decimals if source.external.decimals is defined else 2 -%}
        cast(cast(replace(nullif(btrim({{ adapter.quote(column.name) }}), ''), '{{ decimal_separator }}', '.') as double) as decimal(100, {{ decimals }}))
      {%- else -%}
        nullif(btrim({{ adapter.quote(column.name) }}), '')
      {%- endif -%} as {{ adapter.quote(column.name) }}
      {%- if not loop.last %}
      ,{%- endif -%}
    {%- endfor -%}
  {%- endif -%}
{%- endmacro -%}
