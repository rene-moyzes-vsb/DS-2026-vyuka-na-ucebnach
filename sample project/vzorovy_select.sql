-- Vyúčtování aktivních účastníků vybraného výletu.
-- Pro jiný výlet změňte hodnotu trip_id v CTE selected_trip.
WITH selected_trip AS (
    SELECT 1::integer AS trip_id
),
participant_shares AS (
    SELECT
        es.participant_id,
        sum(es.share_amount) AS total_share
    FROM trips.expense_shares AS es
    JOIN trips.expenses AS expense ON expense.expense_id = es.expense_id
    JOIN selected_trip AS st ON st.trip_id = expense.trip_id
    GROUP BY es.participant_id
),
participant_payments AS (
    SELECT
        payment.participant_id,
        sum(payment.amount) AS total_paid
    FROM trips.payments AS payment
    JOIN trips.participants AS participant
        ON participant.participant_id = payment.participant_id
    JOIN selected_trip AS st ON st.trip_id = participant.trip_id
    WHERE payment.is_confirmed
    GROUP BY payment.participant_id
)
SELECT
    trip.name AS trip_name,
    member.first_name,
    member.last_name,
    CASE
        WHEN participant.is_leader THEN 'Vedoucí'
        ELSE 'Účastník'
    END AS participant_role,
    coalesce(ps.total_share, 0)::numeric(10, 2) AS total_share,
    coalesce(pp.total_paid, 0)::numeric(10, 2) AS total_paid,
    (
        coalesce(ps.total_share, 0) - coalesce(pp.total_paid, 0)
    )::numeric(10, 2) AS balance
FROM selected_trip AS st
JOIN trips.trips AS trip ON trip.trip_id = st.trip_id
JOIN trips.participants AS participant ON participant.trip_id = trip.trip_id
JOIN trips.members AS member ON member.member_id = participant.member_id
LEFT JOIN participant_shares AS ps
    ON ps.participant_id = participant.participant_id
LEFT JOIN participant_payments AS pp
    ON pp.participant_id = participant.participant_id
WHERE participant.is_active
ORDER BY member.last_name, member.first_name;
