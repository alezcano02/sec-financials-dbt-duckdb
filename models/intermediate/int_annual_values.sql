-- One value per company, year and line item.
-- Different companies use different XBRL tags for the same thing (revenue has at least 4),
-- so we map the tags to one line item and keep the first one available by priority.

with mapeo as (
    select * from (values
        ('Revenues', 'revenue', 1),
        ('RevenueFromContractWithCustomerExcludingAssessedTax', 'revenue', 2),
        ('SalesRevenueNet', 'revenue', 3),
        ('RevenuesNetOfInterestExpense', 'revenue', 4),
        ('NetIncomeLoss', 'net_income', 1),
        ('OperatingIncomeLoss', 'operating_income', 1),
        ('Assets', 'total_assets', 1),
        ('Liabilities', 'total_liabilities', 1),
        ('StockholdersEquity', 'equity', 1),
        ('StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest', 'equity', 2),
        ('CashAndCashEquivalentsAtCarryingValue', 'cash', 1),
        ('NetCashProvidedByUsedInOperatingActivities', 'operating_cash_flow', 1),
        ('PaymentsToAcquirePropertyPlantAndEquipment', 'capex', 1),
        ('ResearchAndDevelopmentExpense', 'rnd_expense', 1),
        ('LongTermDebtNoncurrent', 'long_term_debt', 1),
        ('LongTermDebt', 'long_term_debt', 2),
        ('EarningsPerShareDiluted', 'eps_diluted', 1)
    ) as t(concept, line_item, priority)
),

valores as (
    select
        f.cik,
        f.calendar_year,
        m.line_item,
        f.value,
        m.priority,
        row_number() over (partition by f.cik, f.calendar_year, m.line_item order by m.priority, f.filed_date desc) as rn
    from {{ ref('stg_facts') }} f
    join mapeo m on f.concept = m.concept
    -- flows must be annual (not a balance) and balances must be instant values
    where (m.line_item in ('total_assets', 'total_liabilities', 'equity', 'cash', 'long_term_debt') and f.frame_type = 'instant')
       or (m.line_item not in ('total_assets', 'total_liabilities', 'equity', 'cash', 'long_term_debt') and f.frame_type = 'duration')
)

select cik, calendar_year, line_item, value
from valores
where rn = 1
