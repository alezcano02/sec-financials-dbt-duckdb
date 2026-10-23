# Download the XBRL "company facts" of the 100 biggest US listed companies from the SEC
# and save only the accounting concepts we use, in one parquet file (the raw layer).
#
# SEC asks for a User-Agent with a name and an email, and maximum 10 requests per second.

import json
import time
from pathlib import Path

import pandas as pd
import requests

carpeta = Path(__file__).resolve().parents[1] / "data" / "raw"
carpeta.mkdir(parents=True, exist_ok=True)
headers = {"User-Agent": "Alejandro Lezcano Osorio alezcano02@gmail.com", "Accept-Encoding": "gzip, deflate"}

conceptos = [
    "Revenues", "RevenueFromContractWithCustomerExcludingAssessedTax", "SalesRevenueNet", "RevenuesNetOfInterestExpense",
    "NetIncomeLoss", "OperatingIncomeLoss", "Assets", "Liabilities", "StockholdersEquity",
    "StockholdersEquityIncludingPortionAttributableToNoncontrollingInterest", "CashAndCashEquivalentsAtCarryingValue",
    "NetCashProvidedByUsedInOperatingActivities", "PaymentsToAcquirePropertyPlantAndEquipment",
    "ResearchAndDevelopmentExpense", "LongTermDebtNoncurrent", "LongTermDebt", "EarningsPerShareDiluted",
]

# the file of tickers is ordered by market value, we take the first 100 different companies
tickers = requests.get("https://www.sec.gov/files/company_tickers.json", headers=headers, timeout=60).json()
empresas = pd.DataFrame(tickers.values()).drop_duplicates("cik_str").head(100)

filas, info = [], []
for _, e in empresas.iterrows():
    cik = str(e["cik_str"]).zfill(10)
    r1 = requests.get(f"https://data.sec.gov/api/xbrl/companyfacts/CIK{cik}.json", headers=headers, timeout=60)
    r2 = requests.get(f"https://data.sec.gov/submissions/CIK{cik}.json", headers=headers, timeout=60)
    if r1.status_code != 200 or r2.status_code != 200:
        # some foreign companies do not file XBRL facts, we skip them
        print(e["ticker"], "skipped", r1.status_code, r2.status_code)
        continue
    facts, sub = r1.json(), r2.json()
    info.append({"cik": int(cik), "ticker": e["ticker"], "name": e["title"], "sic": sub.get("sic"),
                 "sic_description": sub.get("sicDescription"), "fiscal_year_end": sub.get("fiscalYearEnd")})
    gaap = facts.get("facts", {}).get("us-gaap", {})
    for c in conceptos:
        if c not in gaap:
            continue
        for unidad, valores in gaap[c]["units"].items():
            for v in valores:
                # only the values that SEC assigns to a calendar frame (no duplicates). We do not filter by form:
                # SEC gives the frame to the most recent filing, so a year-end balance can come from the next 10-Q
                if v.get("frame") and (len(v["frame"]) == 6 or v["frame"].endswith("Q4I")):
                    filas.append({"cik": int(cik), "concept": c, "unit": unidad, "start": v.get("start"), "end": v["end"],
                                  "value": v["val"], "fy": v.get("fy"), "fp": v.get("fp"), "form": v["form"],
                                  "filed": v["filed"], "frame": v["frame"], "accn": v["accn"]})
    time.sleep(0.25)
    print(e["ticker"], len(filas))

pd.DataFrame(filas).to_parquet(carpeta / "facts.parquet", index=False)
pd.DataFrame(info).to_csv(carpeta / "companies.csv", index=False)
print("facts:", len(filas), "| companies:", len(info))
