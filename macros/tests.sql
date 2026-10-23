-- Generic tests that we use in schema.yml

{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as n
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}

{% test positive_or_null(model, column_name) %}
select * from {{ model }} where {{ column_name }} <= 0
{% endtest %}

{% test between_or_null(model, column_name, low, high) %}
select * from {{ model }} where {{ column_name }} < {{ low }} or {{ column_name }} > {{ high }}
{% endtest %}
