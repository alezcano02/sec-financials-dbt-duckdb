-- One row per company, with a simple sector built from the SIC code

select
    cik,
    ticker,
    name,
    cast(sic as integer) as sic,
    sic_description,
    case
        when cast(sic as integer) between 6000 and 6299 then 'Banks and finance'
        when cast(sic as integer) between 6300 and 6499 then 'Insurance'
        when cast(sic as integer) between 6500 and 6799 then 'Real estate and holdings'
        when cast(sic as integer) in (3570, 3571, 3572, 3576, 3577, 3661, 3663, 3672, 3674, 3679) then 'Technology hardware'
        when cast(sic as integer) between 7370 and 7379 then 'Software and internet'
        when cast(sic as integer) between 2830 and 2836 or cast(sic as integer) between 8000 and 8099 then 'Health care'
        when cast(sic as integer) between 1300 and 1399 or cast(sic as integer) between 2900 and 2999 then 'Energy'
        when cast(sic as integer) between 4800 and 4899 then 'Telecom and media'
        when cast(sic as integer) between 5200 and 5999 then 'Retail'
        when cast(sic as integer) between 2000 and 3999 then 'Manufacturing'
        else 'Other'
    end as sector
from read_csv_auto('data/raw/companies.csv')
