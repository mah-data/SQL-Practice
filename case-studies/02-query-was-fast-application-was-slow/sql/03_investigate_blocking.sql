/*
    SQL Server Performance Case Study #02
    The Query Was Fast. The Application Was Slow.

    Purpose:
    Investigate active blocking sessions.
*/


/* =========================================================
   1. FIND BLOCKED REQUESTS
   ========================================================= */

SELECT
    session_id,
    blocking_session_id,
    status,
    wait_type,
    wait_time,
    wait_resource,
    command
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
GO


/* =========================================================
   2. INVESTIGATE THE BLOCKER SESSION
   ========================================================= */

SELECT
    session_id,
    status,
    open_transaction_count,
    login_name,
    host_name,
    program_name
FROM sys.dm_exec_sessions
WHERE session_id IN
(
    SELECT DISTINCT blocking_session_id
    FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0
);
GO


/* =========================================================
   3. INVESTIGATE THE ACTIVE TRANSACTION
   ========================================================= */

SELECT
    st.session_id,
    at.transaction_id,
    at.transaction_begin_time,
    at.transaction_type,
    at.transaction_state
FROM sys.dm_tran_session_transactions AS st
JOIN sys.dm_tran_active_transactions AS at
    ON st.transaction_id = at.transaction_id
WHERE st.session_id IN
(
    SELECT DISTINCT blocking_session_id
    FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0
);
GO


/* =========================================================
   4. FIND THE SQL THAT CREATED THE BLOCKER
   ========================================================= */

SELECT
    s.session_id,
    s.status,
    s.open_transaction_count,
    s.login_name,
    s.host_name,
    s.program_name,
    ib.event_info
FROM sys.dm_exec_sessions AS s
OUTER APPLY sys.dm_exec_input_buffer
(
    s.session_id,
    NULL
) AS ib
WHERE s.session_id IN
(
    SELECT DISTINCT blocking_session_id
    FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0
);
GO