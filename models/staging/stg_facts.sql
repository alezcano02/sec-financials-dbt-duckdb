-- Raw XBRL facts from the parquet file, with clean types.
-- We keep the calendar frame that SEC gives (CY2024 for flows, CY2024Q4I for balances at year end)
-- because it removes the duplicates of the same number reported again in later filings.

select
    cik,
    concept,
    unit,
    try_cast("start" as date) as period_start,
    cast("end" as date) as period_end,
    cast(value as double) as value,
    form,
    cast(filed as date) as filed_date,
    frame,
    -- flows have a frame like CY2024, balances like CY2024Q4I
    cast(substr(frame, 3, 4) as integer) as calendar_year,
    case when frame like '%I' then 'instant' else 'duration' end as frame_type
from read_parquet('data/raw/facts.parquet')
-- only US dollars: some foreign filers (Toyota, Mitsubishi UFJ, ASML...) report in their own currency and would mix units
where unit in ('USD', 'USD/shares')
  and (frame similar to 'CY[0-9]{4}' or frame similar to 'CY[0-9]{4}Q4I')
