## 1.1.2 (2026-11-20)

* Updated delta_trace_db to 0.5.0.
* CSV import: importing into an existing collection that has no items no longer shows a failure message
  even though the items were added.
* Filter: date-times without a time zone are no longer shifted on a machine with daylight saving time.

## 1.1.1 (2026-11-18)

* Updated delta_trace_db to 0.4.0.
* CSV import: the CSV is checked with UtilCsv of DeltaTraceDB (the error messages are unchanged),
  and is added with the addCsv / clearAddCsv queries, so the query that contains the CSV text is recorded.

## 1.1.0 (2026-11-15)

* Updated delta_trace_db to 0.3.0.
* Filter: added Decimal and Rational types. Date-times are parsed with the same strict rules as
  DeltaTraceDB, and inputs without a time zone are treated as UTC.
* Added CSV import (UTF-8 only). Each row becomes an item of {header: cell text} in a new or replaced collection.
* Added conversion of a key's values to int / double / bool / String.

## 1.0.1 (2026-05-02)

* The filters are now always reset when a DB is imported again.

## 1.0.0 (2026-05-02)

* For delta_trace_db 0.1.6. Significant improvements to the product level.
