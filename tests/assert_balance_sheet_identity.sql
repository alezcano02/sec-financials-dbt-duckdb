-- Assets = liabilities + equity. We allow 5% of difference because some companies report
-- equity with or without minority interests and mezzanine items (temporary equity).
-- It is a warning and not an error: the rows that break it are real (equity reported without minority
-- interests or with temporary equity), we list them in the notebook instead of hiding them.
{{ config(severity='warn') }}

select ticker, calendar_year, total_assets, total_liabilities, equity,
       abs(total_assets - total_liabilities - equity) / total_assets as gap
from {{ ref('fct_annual_financials') }}
where total_assets > 0 and total_liabilities is not null and equity is not null
  and abs(total_assets - total_liabilities - equity) / total_assets > 0.05
