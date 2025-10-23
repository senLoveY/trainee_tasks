CREATE OR REPLACE TEMPORARY TABLE source_data (
    param1 DATE,
    param2 TIMESTAMP_NTZ
);

INSERT INTO source_data (param1, param2) VALUES
                                             ('2025-02-06', '2025-02-12 09:38:25.999982'),
                                             ('2025-02-14', '2025-02-14 16:17:14.095384'),
                                             ('2025-02-20', '2025-02-21 08:41:53.643244'),
                                             ('2025-02-25', '2025-03-11 15:52:28.575590'),
                                             ('2025-03-06', '2025-03-13 15:35:21.729785'),
                                             ('2025-03-13', '2025-03-13 16:32:27.178218'),
                                             ('2025-03-20', '2025-03-26 08:35:19.585812'),
                                             ('2025-03-27', '2025-03-28 07:23:03.611707'),
                                             ('2025-04-07', '2025-04-08 18:57:03.804270'),
                                             ('2025-04-10', '2025-04-15 11:19:51.275211'),
                                             ('2025-04-14', '2025-04-15 14:34:32.097939'),
                                             ('2025-04-24', '2025-04-24 14:41:48.705573'),
                                             ('2025-05-02', '2025-05-08 11:05:44.640510'),
                                             ('2025-05-15', '2025-05-21 10:00:08.361011'),
                                             ('2025-05-22', '2025-05-28 08:07:06.096731'),
                                             ('2025-05-29', '2025-05-30 10:01:45.906511'),
                                             ('2025-06-05', '2025-06-09 09:22:04.668390'),
                                             ('2025-06-19', '2025-07-03 08:27:40.115104'),
                                             ('2025-06-26', '2025-07-03 09:15:38.292950'),
                                             ('2025-07-03', '2025-07-07 10:53:30.915895');

CREATE OR REPLACE TABLE test2_call_log (
    call_id INT AUTOINCREMENT,
    param1 DATE,
    param2 TIMESTAMP_NTZ,
    param3 DATE,
    call_time TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


CREATE OR REPLACE PROCEDURE test_2(PARAM1 DATE, PARAM2 TIMESTAMP_NTZ, PARAM3 DATE)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
INSERT INTO test2_call_log (param1, param2, param3)
VALUES (:PARAM1, :PARAM2, :PARAM3);
END;
$$;

CREATE OR REPLACE PROCEDURE call_test2_sequence()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
  let prev_date = '2025-01-28';

  const rows = [];
  const sql_query = `
    SELECT param1::STRING, param2::STRING
    FROM source_data
    ORDER BY param1
  `;

  const stmt = snowflake.createStatement({ sqlText: sql_query });
  const rs = stmt.execute();

  while (rs.next()) {
    rows.push([rs.getColumnValue(1), rs.getColumnValue(2)]);
}

  if (rows.length === 0) {
    return "No data found in source_data.";
}

  let executed = 0;
for (let i = 0; i < rows.length; i++) {
    const curr_date = rows[i][0];
    const ts = rows[i][1];

    const call_sql = `CALL test_2('${curr_date}', '${ts}', '${prev_date}')`;
    snowflake.execute({ sqlText: call_sql });

    prev_date = curr_date;
    executed++;
}

  return "Successfully executed " + executed + " calls with initial date '2025-01-28'.";
$$;

CALL call_test2_sequence();

SELECT * FROM test2_call_log ORDER BY call_time;