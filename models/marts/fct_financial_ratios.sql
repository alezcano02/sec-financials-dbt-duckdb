-- Profitability, leverage, cash generation and growth ratios.
-- We divide only when the denominator is positive, otherwise the ratio has no meaning.

with base as (
    select
        *,
        lag(revenue) over (partition by cik order by calendar_year) as revenue_prev,
        lag(equity) over (partition by cik order by calendar_year) as equity_prev,
        lag(total_assets) over (partition by cik order by calendar_year) as assets_prev
    from {{ ref('fct_annual_financials') }}
)

select
    cik,
    ticker,
    name,
    sector,
    calendar_year,
    revenue,
    net_income,
    case when revenue > 0 then operating_income / revenue end as operating_margin,
    case when revenue > 0 then net_income / revenue end as net_margin,
    -- ROE and ROA with the average of the opening and closing balance
    case when (equity + equity_prev) > 0 then net_income / ((equity + equity_prev) / 2) end as roe,
    case when (total_assets + assets_prev) > 0 then net_income / ((total_assets + assets_prev) / 2) end as roa,
    case when equity > 0 then total_liabilities / equity end as liabilities_to_equity,
    case when total_assets > 0 then equity / total_assets end as equity_ratio,
    case when net_income > 0 then (operating_cash_flow - coalesce(capex, 0)) / net_income end as fcf_to_net_income,
    operating_cash_flow - coalesce(capex, 0) as free_cash_flow,
    case when revenue > 0 then rnd_expense / revenue end as rnd_intensity,
    case when revenue_prev > 0 then revenue / revenue_prev - 1 end as revenue_growth
from base
