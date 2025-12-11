-- Bantora Test Data (Hibernate Auto-DDL compatible)
-- Provides seed data for 3-column layout testing

-- Test user for foreign key constraints
INSERT INTO bantora_users (phone_number, password_hash, full_name, country_code, verified, enabled, preferred_language, created_at, updated_at)
VALUES ('+263785107830', '$argon2id$v=19$m=16384,t=2,p=1$1EuEeVyVcNttvsudvsmB3g$rpDHS4jfdVa5FE9h3IgJKbv6xbpe/tpxAegLg3DdtrI', 'Tsungai Kaviya', 'ZW', true, true, 'en', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================================================
-- POPULAR POLLS (High votes, for "Popular" column)
-- ============================================================================

-- Poll 1: Pan-African Currency (93% Yes, 15420 total votes)
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440001',
    'Should Africa establish a unified currency?',
    'A continental currency union could boost trade, reduce exchange costs, and strengthen Africa''s economic position globally.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '30' DAY,
    CURRENT_TIMESTAMP + INTERVAL '30' DAY,
    15420,
    CURRENT_TIMESTAMP - INTERVAL '30' DAY,
    CURRENT_TIMESTAMP - INTERVAL '30' DAY,
    'Economy'
);

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000001', '550e8400-e29b-41d4-a716-446655440001', 'Yes', 1, 14341),
    ('5500-opt2-0000-0000-000000000001', '550e8400-e29b-41d4-a716-446655440001', 'No', 2, 1079);

-- Poll 2: Continental Free Trade (83% Yes, 12850 total votes)
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440002',
    'Expand African Continental Free Trade Area (AfCFTA)?',
    'The AfCFTA aims to create a single market for goods and services across Africa. Accelerate implementation?',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '25' DAY,
    CURRENT_TIMESTAMP + INTERVAL '35' DAY,
    12850,
    CURRENT_TIMESTAMP - INTERVAL '25' DAY,
    CURRENT_TIMESTAMP - INTERVAL '25' DAY,
    'Trade'
);

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000002', '550e8400-e29b-41d4-a716-446655440002', 'Yes', 1, 10666),
    ('5500-opt2-0000-0000-000000000002', '550e8400-e29b-41d4-a716-446655440002', 'No', 2, 2184);

-- Poll 3: Unified Passport (74% Yes, 10935 total votes)
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440003',
    'Implement a unified African passport for all citizens?',
    'A single African passport would enable free movement across the continent, boost tourism, and strengthen Pan-African identity.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '20' DAY,
    CURRENT_TIMESTAMP + INTERVAL '40' DAY,
    10935,
    CURRENT_TIMESTAMP - INTERVAL '20' DAY,
    CURRENT_TIMESTAMP - INTERVAL '20' DAY,
    'Identity'
);

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000003', '550e8400-e29b-41d4-a716-446655440003', 'Yes', 1, 8092),
    ('5500-opt2-0000-0000-000000000003', '550e8400-e29b-41d4-a716-446655440003', 'No', 2, 2843);

-- ============================================================================
-- NEW/AI POLLS (Recent, lower votes, for "New/AI" column)
-- ============================================================================

-- Poll 4: Renewable Energy (67% Yes, 487 votes)
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440004',
    'Prioritize solar and wind energy for Africa''s power grid?',
    'AI analysis suggests renewable energy could solve Africa''s power deficit sustainably.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '3' DAY,
    CURRENT_TIMESTAMP + INTERVAL '27' DAY,
    487,
    CURRENT_TIMESTAMP - INTERVAL '3' DAY,
    CURRENT_TIMESTAMP - INTERVAL '3' DAY,
    'Energy'
);

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000004', '550e8400-e29b-41d4-a716-446655440004', 'Yes', 1, 326),
    ('5500-opt2-0000-0000-000000000004', '550e8400-e29b-41d4-a716-446655440004', 'No', 2, 161);

-- Poll 5: Digital Education (88% Yes, 312 votes)
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440005',
    'Launch a pan-African online education platform?',
    'An AI-powered education platform could provide quality learning resources to millions across the continent.',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '2' DAY,
    CURRENT_TIMESTAMP + INTERVAL '28' DAY,
    312,
    CURRENT_TIMESTAMP - INTERVAL '2' DAY,
    CURRENT_TIMESTAMP - INTERVAL '2' DAY,
    'Education'
);

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000005', '550e8400-e29b-41d4-a716-446655440005', 'Yes', 1, 275),
    ('5500-opt2-0000-0000-000000000005', '550e8400-e29b-41d4-a716-446655440005', 'No', 2, 37);

-- Poll 6: Youth Employment (71% Yes, 156 votes)
INSERT INTO bantora_polls (id, title, description, creator_phone, scope, status, start_time, end_time, total_votes, created_at, updated_at, category)
VALUES (
    '550e8400-e29b-41d4-a716-446655440006',
    'Create a continental youth employment program?',
    'AI-identified skills gaps: tech, agriculture, healthcare. Should AU fund training programs?',
    '+263785107830',
    'CONTINENTAL',
    'ACTIVE',
    CURRENT_TIMESTAMP - INTERVAL '1' DAY,
    CURRENT_TIMESTAMP + INTERVAL '29' DAY,
    156,
    CURRENT_TIMESTAMP - INTERVAL '1' DAY,
    CURRENT_TIMESTAMP - INTERVAL '1' DAY,
    'Employment'
);

INSERT INTO bantora_poll_options (id, poll_id, option_text, option_order, votes_count)
VALUES 
    ('5500-opt1-0000-0000-000000000006', '550e8400-e29b-41d4-a716-446655440006', 'Yes', 1, 111),
    ('5500-opt2-0000-0000-000000000006', '550e8400-e29b-41d4-a716-446655440006', 'No', 2, 45);

-- ============================================================================
-- RAW IDEAS (For "Raw Ideas" column)
-- ============================================================================

-- Idea 1: Agricultural Technology
INSERT INTO bantora_ideas (id, user_phone, content, status, created_at, upvotes)
VALUES (
    '660e8400-e29b-41d4-a716-446655440001',
    '+263785107830',
    'We need affordable drip irrigation systems for small-scale farmers across Africa. Current systems are too expensive for most farmers who could benefit from water conservation technology.',
    'PENDING',
    CURRENT_TIMESTAMP - INTERVAL '2' HOUR,
    23
);

-- Idea 2: Healthcare Access
INSERT INTO bantora_ideas (id, user_phone, content, status, created_at, upvotes)
VALUES (
    '660e8400-e29b-41d4-a716-446655440002',
    '+263785107830',
    'Mobile health clinics could reach rural areas without hospitals. Equip vans with basic medical equipment and rotate doctors through underserved regions monthly.',
    'PENDING',
    CURRENT_TIMESTAMP - INTERVAL '4' HOUR,
    18
);

-- Idea 3: Infrastructure Development
INSERT INTO bantora_ideas (id, user_phone, content, status, created_at, upvotes)
VALUES (
    '660e8400-e29b-41d4-a716-446655440003',
    '+263785107830',
    'Build a trans-African railway network connecting all capitals. This would boost trade, tourism, and cultural exchange while creating millions of jobs during construction.',
    'PENDING',
    CURRENT_TIMESTAMP - INTERVAL '6' HOUR,
    41
);
