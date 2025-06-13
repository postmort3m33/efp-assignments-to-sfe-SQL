-- Created by Joshua Touchstone 06/12/2025
-- Pre-formatted SQL to export employee assignments from eFinancePlus and import them directly into SmartFind Express (E1 Import)

-- USE: Replace table placeholder with your own database.
-- Main eFinance Database Table = [EFPTABLEHERE] - Line 49,51


SELECT
    'E' AS 'Record Type',
    'A' AS 'Record Command',
    '1' AS 'Record Number',
    a.empl_no AS 'Employee Number',

    -- Location Order
    CASE
        WHEN a.primary_asn = 'Y' THEN 0
        ELSE RANK() OVER (PARTITION BY a.empl_no ORDER BY a.location) - 1
    END AS 'Location Order',

    a.location AS 'Location Code',

    -- Classification Order
    CASE
        WHEN a.primary_asn = 'Y' THEN 0 -- Rule 1: If THIS assignment is primary ('Y'), it's 0.
        ELSE
            CASE
                -- Rule 2: If there's ONLY ONE assignment for this Unique Employee/Location
                -- (and it's not primary, because Rule 1 already caught that), it's 0.
                WHEN COUNT(a.empl_no) OVER (PARTITION BY a.empl_no, a.location) = 1 THEN 0
                -- Rule 3: Otherwise (multiple assignments for this Unique Employee/Location,
                -- AND the current one is NOT primary):
                -- Calculate a running count that ONLY increments for non-primary assignments.
                ELSE
                    SUM(CASE WHEN a.primary_asn = 'N' THEN 1 ELSE 0 END) OVER (
                        PARTITION BY a.empl_no, a.location
                        ORDER BY a.asncode -- Ensure stable order for the running count
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- Standard for a running sum
                    )
            END
    END AS 'Classification Order',

    a.asncode AS 'Classification Code',
    '' AS 'Start Time',
    '' AS 'End Time',
    'Y' AS 'Use Location Times (Y/N)',
    'NYYYYYN' AS 'Day of the Week',
    '' AS 'Closing Delimeter'
FROM
    [EFPTABLEHERE].[dbo].[assignment] AS a
INNER JOIN
    [EFPTABLEHERE].[dbo].[payrate] AS p
ON
    a.empl_no = p.empl_no
WHERE
    p.status_x = 'A'
    AND p.primry = 'P'
    AND a.location IS NOT NULL;
