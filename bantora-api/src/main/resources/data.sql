-- Bantora Test Data
-- Flyway data migration for R2DBC

-- Test user
INSERT INTO bantora_users (phone_number, password_hash, full_name, country_code, verified, enabled, preferred_language, created_at, updated_at)
VALUES ('+263785107830', '$argon2id$v=19$m=16384,t=2,p=1$1EuEeVyVcNttvsudvsmB3g$rpDHS4jfdVa5FE9h3IgJKbv6xbpe/tpxAegLg3DdtrI', 'Tsungai Kaviya', 'ZW', true, true, 'en', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (phone_number) DO NOTHING;

-- Popular Poll 1
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440001',
    'Should Africa establish a unified currency?',
    'A continental currency union could boost trade, reduce exchange costs, and strengthen Africa''s economic position globally.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    CURRENT_TIMESTAMP + INTERVAL '30 days',
    15420,
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    'Economy'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000001', '550e8400-e29b-41d4-a716-446655440001', 'Yes', 1, 14341),
    ('5500-opt2-0000-0000-000000000001', '550e8400-e29b-41d4-a716-446655440001', 'No', 2, 1079)
ON CONFLICT (id) DO NOTHING;

-- Popular Poll 2
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440002',
    'Expand African Continental Free Trade Area (AfCFTA)?',
    'The AfCFTA aims to create a single market for goods and services across Africa. Accelerate implementation?',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '25 days',
    CURRENT_TIMESTAMP + INTERVAL '35 days',
    12850,
    CURRENT_TIMESTAMP - INTERVAL '25 days',
    CURRENT_TIMESTAMP - INTERVAL '25 days',
    'Trade'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000002', '550e8400-e29b-41d4-a716-446655440002', 'Yes', 1, 10666),
    ('5500-opt2-0000-0000-000000000002', '550e8400-e29b-41d4-a716-446655440002', 'No', 2, 2184)
ON CONFLICT (id) DO NOTHING;

-- Popular Poll 3
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440003',
    'Implement a unified African passport for all citizens?',
    'A single African passport would enable free movement across the continent, boost tourism, and strengthen Pan-African identity.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '20 days',
    CURRENT_TIMESTAMP + INTERVAL '40 days',
    10935,
    CURRENT_TIMESTAMP - INTERVAL '20 days',
    CURRENT_TIMESTAMP - INTERVAL '20 days',
    'Identity'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000003', '550e8400-e29b-41d4-a716-446655440003', 'Yes', 1, 8092),
    ('5500-opt2-0000-0000-000000000003', '550e8400-e29b-41d4-a716-446655440003', 'No', 2, 2843)
ON CONFLICT (id) DO NOTHING;

-- New/AI Poll 1
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440004',
    'Prioritize solar and wind energy for Africa''s power grid?',
    'AI analysis suggests renewable energy could solve Africa''s power deficit sustainably.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP + INTERVAL '27 days',
    487,
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    'Energy'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000004', '550e8400-e29b-41d4-a716-446655440004', 'Yes', 1, 326),
    ('5500-opt2-0000-0000-000000000004', '550e8400-e29b-41d4-a716-446655440004', 'No', 2, 161)
ON CONFLICT (id) DO NOTHING;

-- New/AI Poll 2
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440005',
    'Launch a pan-African online education platform?',
    'An AI-powered education platform could provide quality learning resources to millions across the continent.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP + INTERVAL '28 days',
    312,
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    'Education'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000005', '550e8400-e29b-41d4-a716-446655440005', 'Yes', 1, 275),
    ('5500-opt2-0000-0000-000000000005', '550e8400-e29b-41d4-a716-446655440005', 'No', 2, 37)
ON CONFLICT (id) DO NOTHING;

-- New/AI Poll 3
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440006',
    'Create a continental youth employment program?',
    'AI-identified skills gaps: tech, agriculture, healthcare. Should AU fund training programs?',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    CURRENT_TIMESTAMP + INTERVAL '29 days',
    156,
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'Employment'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000006', '550e8400-e29b-41d4-a716-446655440006', 'Yes', 1, 111),
    ('5500-opt2-0000-0000-000000000006', '550e8400-e29b-41d4-a716-446655440006', 'No', 2, 45)
ON CONFLICT (id) DO NOTHING;

-- Raw Ideas
INSERT INTO bantora_ideas (id, user_phone, content, status, created_at, upvotes)
VALUES (
    '660e8400-e29b-41d4-a716-446655440001',
    '+263785107830',
    'We need affordable drip irrigation systems for small-scale farmers across Africa. Current systems are too expensive for most farmers who could benefit from water conservation technology.',
    'PENDING',
    CURRENT_TIMESTAMP - INTERVAL '2 hours',
    23
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_ideas (id, user_phone, content, status, created_at, upvotes)
VALUES (
    '660e8400-e29b-41d4-a716-446655440002',
    '+263785107830',
    'Mobile health clinics could reach rural areas without hospitals. Equip vans with basic medical equipment and rotate doctors through underserved regions monthly.',
    'PENDING',
    CURRENT_TIMESTAMP - INTERVAL '4 hours',
    18
) ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_ideas (id, user_phone, content, status, created_at, upvotes)
VALUES (
    '660e8400-e29b-41d4-a716-446655440003',
    '+263785107830',
    'Build a trans-African railway network connecting all capitals. This would boost trade, tourism, and cultural exchange while creating millions of jobs during construction.',
    'PENDING',
    CURRENT_TIMESTAMP - INTERVAL '6 hours',
    41
) ON CONFLICT (id) DO NOTHING;
