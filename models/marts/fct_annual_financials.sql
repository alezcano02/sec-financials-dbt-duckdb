-- Wide table: one row per company and calendar year, one column per line item

select
    c.cik,
    c.ticker,
    c.name,
    c.sector,
    v.calendar_year,
    max(case when line_item = 'revenue' then value end) as revenue,
    max(case when line_item = 'operating_income' then value end) as operating_income,
    max(case when line_item = 'net_income' then value end) as net_income,
    max(case when line_item = 'total_assets' then value end) as total_assets,
    max(case when line_item = 'total_liabilities' then value end) as total_liabilities,
    max(case when line_item = 'equity' then value end) as equity,
    max(case when line_item = 'cash' then value end) as cash,
    max(case when line_item = 'long_term_debt' then value end) as long_term_debt,
    max(case when line_item = 'operating_cash_flow' then value end) as operating_cash_flow,
    max(case when line_item = 'capex' then value end) as capex,
    max(case when line_item = 'rnd_expense' then value end) as rnd_expense,
    max(case when line_item = 'eps_diluted' then value end) as eps_diluted
from {{ ref('int_annual_values') }} v
join {{ ref('stg_companies') }} c on v.cik = c.cik
where v.calendar_year between 2010 and 2025
group by all
