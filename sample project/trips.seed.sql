INSERT INTO trips.members
    (member_id, first_name, last_name, registered_at, is_active)
VALUES
    (1, 'Anna', 'Nováková', '2025-01-10 09:00:00+01', true),
    (2, 'David', 'Dvořák', '2025-01-11 10:30:00+01', true),
    (3, 'Eva', 'Svobodová', '2025-01-12 14:15:00+01', true);

INSERT INTO trips.trips
    (trip_id, name, starts_on, ends_on, expected_cost)
VALUES
    (1, 'Víkend v Praze', '2025-05-16', '2025-05-18', 8000.00);

INSERT INTO trips.participants
    (participant_id, member_id, trip_id, is_active, is_leader)
VALUES
    (1, 1, 1, true, true),
    (2, 2, 1, true, false),
    (3, 3, 1, true, false);

INSERT INTO trips.services (service_id, name, is_active)
VALUES
    (1, 'Ubytování', true),
    (2, 'Doprava', true),
    (3, 'Strava', true);

INSERT INTO trips.expenses
    (expense_id, service_id, trip_id, amount, occurred_at, description)
VALUES
    (1, 1, 1, 4800.00, '2025-05-16 18:00:00+02', 'Ubytování na dvě noci'),
    (2, 2, 1, 1200.00, '2025-05-16 12:00:00+02', 'Společná doprava'),
    (3, 3, 1, 1800.00, '2025-05-17 13:00:00+02', 'Společné jídlo');

INSERT INTO trips.expense_shares
    (expense_share_id, participant_id, expense_id, share_amount, description)
VALUES
    (1, 2, 1, 2400.00, NULL),
    (2, 3, 1, 2400.00, NULL),
    (3, 2, 2, 600.00, NULL),
    (4, 3, 2, 600.00, NULL),
    (5, 2, 3, 900.00, NULL),
    (6, 3, 3, 900.00, NULL);

INSERT INTO trips.payments
    (payment_id, participant_id, is_confirmed, amount, paid_at)
VALUES
    (1, 1, true, 3000.00, '2025-05-18 17:00:00+02'),
    (2, 2, true, 2000.00, '2025-05-18 17:05:00+02'),
    (3, 3, true, 2800.00, '2025-05-18 17:10:00+02');

-- Posune identity sekvence za explicitně vložená ID, aby další INSERT bez ID nekolidoval.
SELECT setval(pg_get_serial_sequence('trips.members', 'member_id'),
              (SELECT max(member_id) FROM trips.members));
SELECT setval(pg_get_serial_sequence('trips.trips', 'trip_id'),
              (SELECT max(trip_id) FROM trips.trips));
SELECT setval(pg_get_serial_sequence('trips.participants', 'participant_id'),
              (SELECT max(participant_id) FROM trips.participants));
SELECT setval(pg_get_serial_sequence('trips.services', 'service_id'),
              (SELECT max(service_id) FROM trips.services));
SELECT setval(pg_get_serial_sequence('trips.expenses', 'expense_id'),
              (SELECT max(expense_id) FROM trips.expenses));
SELECT setval(pg_get_serial_sequence('trips.expense_shares', 'expense_share_id'),
              (SELECT max(expense_share_id) FROM trips.expense_shares));
SELECT setval(pg_get_serial_sequence('trips.payments', 'payment_id'),
              (SELECT max(payment_id) FROM trips.payments));
