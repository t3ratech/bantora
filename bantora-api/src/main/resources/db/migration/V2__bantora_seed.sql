-- Bantora Clean-Slate Seed Data (V2)
-- Created: 2025-12-16

-- Countries (African-only)
INSERT INTO bantora_country (code, name, calling_code, currency, default_language, registration_enabled)
VALUES
    ('DZ', 'Algeria', '+213', 'DZD', 'ar', TRUE),
    ('AO', 'Angola', '+244', 'AOA', 'pt', TRUE),
    ('BJ', 'Benin', '+229', 'XOF', 'fr', TRUE),
    ('BW', 'Botswana', '+267', 'BWP', 'en', TRUE),
    ('BF', 'Burkina Faso', '+226', 'XOF', 'fr', TRUE),
    ('BI', 'Burundi', '+257', 'BIF', 'fr', TRUE),
    ('CV', 'Cabo Verde', '+238', 'CVE', 'pt', TRUE),
    ('CM', 'Cameroon', '+237', 'XAF', 'fr', TRUE),
    ('CF', 'Central African Republic', '+236', 'XAF', 'fr', TRUE),
    ('TD', 'Chad', '+235', 'XAF', 'fr', TRUE),
    ('KM', 'Comoros', '+269', 'KMF', 'fr', TRUE),
    ('CD', 'DR Congo', '+243', 'CDF', 'fr', TRUE),
    ('CG', 'Congo', '+242', 'XAF', 'fr', TRUE),
    ('CI', 'Côte d''Ivoire', '+225', 'XOF', 'fr', TRUE),
    ('DJ', 'Djibouti', '+253', 'DJF', 'fr', TRUE),
    ('EG', 'Egypt', '+20', 'EGP', 'ar', TRUE),
    ('GQ', 'Equatorial Guinea', '+240', 'XAF', 'fr', TRUE),
    ('ER', 'Eritrea', '+291', 'ERN', 'ar', TRUE),
    ('SZ', 'Eswatini', '+268', 'SZL', 'en', TRUE),
    ('ET', 'Ethiopia', '+251', 'ETB', 'am', TRUE),
    ('GA', 'Gabon', '+241', 'XAF', 'fr', TRUE),
    ('GM', 'Gambia', '+220', 'GMD', 'en', TRUE),
    ('GH', 'Ghana', '+233', 'GHS', 'en', TRUE),
    ('GN', 'Guinea', '+224', 'GNF', 'fr', TRUE),
    ('GW', 'Guinea-Bissau', '+245', 'XOF', 'pt', TRUE),
    ('KE', 'Kenya', '+254', 'KES', 'sw', TRUE),
    ('LS', 'Lesotho', '+266', 'LSL', 'en', TRUE),
    ('LR', 'Liberia', '+231', 'LRD', 'en', TRUE),
    ('LY', 'Libya', '+218', 'LYD', 'ar', TRUE),
    ('MG', 'Madagascar', '+261', 'MGA', 'fr', TRUE),
    ('MW', 'Malawi', '+265', 'MWK', 'en', TRUE),
    ('ML', 'Mali', '+223', 'XOF', 'fr', TRUE),
    ('MR', 'Mauritania', '+222', 'MRU', 'ar', TRUE),
    ('MU', 'Mauritius', '+230', 'MUR', 'en', TRUE),
    ('MA', 'Morocco', '+212', 'MAD', 'ar', TRUE),
    ('MZ', 'Mozambique', '+258', 'MZN', 'pt', TRUE),
    ('NA', 'Namibia', '+264', 'NAD', 'en', TRUE),
    ('NE', 'Niger', '+227', 'XOF', 'fr', TRUE),
    ('NG', 'Nigeria', '+234', 'NGN', 'en', TRUE),
    ('RW', 'Rwanda', '+250', 'RWF', 'en', TRUE),
    ('ST', 'São Tomé and Príncipe', '+239', 'STN', 'pt', TRUE),
    ('SN', 'Senegal', '+221', 'XOF', 'fr', TRUE),
    ('SC', 'Seychelles', '+248', 'SCR', 'en', TRUE),
    ('SL', 'Sierra Leone', '+232', 'SLE', 'en', TRUE),
    ('SO', 'Somalia', '+252', 'SOS', 'so', TRUE),
    ('ZA', 'South Africa', '+27', 'ZAR', 'en', TRUE),
    ('SS', 'South Sudan', '+211', 'SSP', 'en', TRUE),
    ('SD', 'Sudan', '+249', 'SDG', 'ar', TRUE),
    ('TZ', 'Tanzania', '+255', 'TZS', 'sw', TRUE),
    ('TG', 'Togo', '+228', 'XOF', 'fr', TRUE),
    ('TN', 'Tunisia', '+216', 'TND', 'ar', TRUE),
    ('UG', 'Uganda', '+256', 'UGX', 'en', TRUE),
    ('EH', 'Western Sahara', '+212', 'MAD', 'ar', TRUE),
    ('ZM', 'Zambia', '+260', 'ZMW', 'en', TRUE),
    ('ZW', 'Zimbabwe', '+263', 'ZWL', 'en', TRUE)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    calling_code = EXCLUDED.calling_code,
    currency = EXCLUDED.currency,
    default_language = EXCLUDED.default_language,
    registration_enabled = EXCLUDED.registration_enabled;

-- Categories
INSERT INTO bantora_category (name)
VALUES
    ('Economy'),
    ('Trade'),
    ('Identity'),
    ('Energy'),
    ('Education'),
    ('Employment'),
    ('Agriculture'),
    ('Health'),
    ('Infrastructure'),
    ('Technology'),
    ('Governance'),
    ('Security'),
    ('Environment'),
    ('General')
ON CONFLICT (name) DO NOTHING;

-- Hashtags (stored without '#')
INSERT INTO bantora_hashtag (tag)
VALUES
    ('unified-currency'),
    ('afcfta'),
    ('passport'),
    ('renewables'),
    ('education'),
    ('jobs'),
    ('irrigation'),
    ('health'),
    ('railway')
ON CONFLICT (tag) DO NOTHING;

-- Seed user (for demo + seeded content ownership)
INSERT INTO bantora_user (
    phone_number,
    password_hash,
    full_name,
    country_code,
    verified,
    enabled,
    preferred_language,
    preferred_currency,
    created_at,
    updated_at
)
VALUES (
    '+263785107830',
    '$argon2id$v=19$m=16384,t=2,p=1$1EuEeVyVcNttvsudvsmB3g$rpDHS4jfdVa5FE9h3IgJKbv6xbpe/tpxAegLg3DdtrI',
    'Tsungai Kaviya',
    'ZW',
    TRUE,
    TRUE,
    'en',
    'ZWL',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (phone_number) DO NOTHING;

-- Polls (ACTIVE and not expired)
INSERT INTO bantora_poll (
    id,
    title,
    description,
    creator_phone,
    category_id,
    scope,
    status,
    start_time,
    end_time,
    total_votes,
    created_at,
    updated_at
)
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440001',
        'Should Africa establish a unified currency?',
        'A continental currency union could boost trade, reduce exchange costs, and strengthen Africa''s economic position globally.',
        '+263785107830',
        (SELECT id FROM bantora_category WHERE name = 'Economy'),
        'CONTINENTAL',
        'ACTIVE',
        CURRENT_TIMESTAMP - INTERVAL '30 days',
        CURRENT_TIMESTAMP + INTERVAL '30 days',
        15420,
        CURRENT_TIMESTAMP - INTERVAL '30 days',
        CURRENT_TIMESTAMP - INTERVAL '30 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440002',
        'Expand African Continental Free Trade Area (AfCFTA)?',
        'The AfCFTA aims to create a single market for goods and services across Africa. Accelerate implementation?',
        '+263785107830',
        (SELECT id FROM bantora_category WHERE name = 'Trade'),
        'CONTINENTAL',
        'ACTIVE',
        CURRENT_TIMESTAMP - INTERVAL '25 days',
        CURRENT_TIMESTAMP + INTERVAL '35 days',
        12850,
        CURRENT_TIMESTAMP - INTERVAL '25 days',
        CURRENT_TIMESTAMP - INTERVAL '25 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440003',
        'Implement a unified African passport for all citizens?',
        'A single African passport would enable free movement across the continent, boost tourism, and strengthen Pan-African identity.',
        '+263785107830',
        (SELECT id FROM bantora_category WHERE name = 'Identity'),
        'CONTINENTAL',
        'ACTIVE',
        CURRENT_TIMESTAMP - INTERVAL '20 days',
        CURRENT_TIMESTAMP + INTERVAL '40 days',
        10935,
        CURRENT_TIMESTAMP - INTERVAL '20 days',
        CURRENT_TIMESTAMP - INTERVAL '20 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440004',
        'Prioritize solar and wind energy for Africa''s power grid?',
        'AI analysis suggests renewable energy could solve Africa''s power deficit sustainably.',
        '+263785107830',
        (SELECT id FROM bantora_category WHERE name = 'Energy'),
        'CONTINENTAL',
        'ACTIVE',
        CURRENT_TIMESTAMP - INTERVAL '3 days',
        CURRENT_TIMESTAMP + INTERVAL '27 days',
        487,
        CURRENT_TIMESTAMP - INTERVAL '3 days',
        CURRENT_TIMESTAMP - INTERVAL '3 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440005',
        'Launch a pan-African online education platform?',
        'An AI-powered education platform could provide quality learning resources to millions across the continent.',
        '+263785107830',
        (SELECT id FROM bantora_category WHERE name = 'Education'),
        'CONTINENTAL',
        'ACTIVE',
        CURRENT_TIMESTAMP - INTERVAL '2 days',
        CURRENT_TIMESTAMP + INTERVAL '28 days',
        312,
        CURRENT_TIMESTAMP - INTERVAL '2 days',
        CURRENT_TIMESTAMP - INTERVAL '2 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440006',
        'Create a continental youth employment program?',
        'AI-identified skills gaps: tech, agriculture, healthcare. Should AU fund training programs?',
        '+263785107830',
        (SELECT id FROM bantora_category WHERE name = 'Employment'),
        'CONTINENTAL',
        'ACTIVE',
        CURRENT_TIMESTAMP - INTERVAL '1 day',
        CURRENT_TIMESTAMP + INTERVAL '29 days',
        156,
        CURRENT_TIMESTAMP - INTERVAL '1 day',
        CURRENT_TIMESTAMP - INTERVAL '1 day'
    )
ON CONFLICT (id) DO NOTHING;

-- Poll options
INSERT INTO bantora_poll_option (id, poll_id, option_text, option_order, votes_count)
VALUES
    ('550e8400-e29b-41d4-a716-446655440101', '550e8400-e29b-41d4-a716-446655440001', 'Yes', 1, 14341),
    ('550e8400-e29b-41d4-a716-446655440102', '550e8400-e29b-41d4-a716-446655440001', 'No', 2, 1079),
    ('550e8400-e29b-41d4-a716-446655440201', '550e8400-e29b-41d4-a716-446655440002', 'Yes', 1, 10666),
    ('550e8400-e29b-41d4-a716-446655440202', '550e8400-e29b-41d4-a716-446655440002', 'No', 2, 2184),
    ('550e8400-e29b-41d4-a716-446655440301', '550e8400-e29b-41d4-a716-446655440003', 'Yes', 1, 8092),
    ('550e8400-e29b-41d4-a716-446655440302', '550e8400-e29b-41d4-a716-446655440003', 'No', 2, 2843),
    ('550e8400-e29b-41d4-a716-446655440401', '550e8400-e29b-41d4-a716-446655440004', 'Yes', 1, 326),
    ('550e8400-e29b-41d4-a716-446655440402', '550e8400-e29b-41d4-a716-446655440004', 'No', 2, 161),
    ('550e8400-e29b-41d4-a716-446655440501', '550e8400-e29b-41d4-a716-446655440005', 'Yes', 1, 275),
    ('550e8400-e29b-41d4-a716-446655440502', '550e8400-e29b-41d4-a716-446655440005', 'No', 2, 37),
    ('550e8400-e29b-41d4-a716-446655440601', '550e8400-e29b-41d4-a716-446655440006', 'Yes', 1, 111),
    ('550e8400-e29b-41d4-a716-446655440602', '550e8400-e29b-41d4-a716-446655440006', 'No', 2, 45)
ON CONFLICT (id) DO NOTHING;

-- Poll hashtags (for filtering)
INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
SELECT '550e8400-e29b-41d4-a716-446655440001', h.id FROM bantora_hashtag h WHERE h.tag = 'unified-currency'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
SELECT '550e8400-e29b-41d4-a716-446655440002', h.id FROM bantora_hashtag h WHERE h.tag = 'afcfta'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
SELECT '550e8400-e29b-41d4-a716-446655440003', h.id FROM bantora_hashtag h WHERE h.tag = 'passport'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
SELECT '550e8400-e29b-41d4-a716-446655440004', h.id FROM bantora_hashtag h WHERE h.tag = 'renewables'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
SELECT '550e8400-e29b-41d4-a716-446655440005', h.id FROM bantora_hashtag h WHERE h.tag = 'education'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
SELECT '550e8400-e29b-41d4-a716-446655440006', h.id FROM bantora_hashtag h WHERE h.tag = 'jobs'
ON CONFLICT DO NOTHING;

-- Ideas (PENDING + with hashtags to satisfy constraint trigger)
INSERT INTO bantora_idea (id, user_phone, content, category_id, status, created_at, upvotes)
VALUES
    (
        '660e8400-e29b-41d4-a716-446655440001',
        '+263785107830',
        'We need affordable drip irrigation systems for small-scale farmers across Africa. Current systems are too expensive for most farmers who could benefit from water conservation technology.',
        (SELECT id FROM bantora_category WHERE name = 'Agriculture'),
        'PENDING',
        CURRENT_TIMESTAMP - INTERVAL '2 hours',
        23
    ),
    (
        '660e8400-e29b-41d4-a716-446655440002',
        '+263785107830',
        'Mobile health clinics could reach rural areas without hospitals. Equip vans with basic medical equipment and rotate doctors through underserved regions monthly.',
        (SELECT id FROM bantora_category WHERE name = 'Health'),
        'PENDING',
        CURRENT_TIMESTAMP - INTERVAL '4 hours',
        18
    ),
    (
        '660e8400-e29b-41d4-a716-446655440003',
        '+263785107830',
        'Build a trans-African railway network connecting all capitals. This would boost trade, tourism, and cultural exchange while creating millions of jobs during construction.',
        (SELECT id FROM bantora_category WHERE name = 'Infrastructure'),
        'PENDING',
        CURRENT_TIMESTAMP - INTERVAL '6 hours',
        41
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO bantora_idea_hashtag (idea_id, hashtag_id)
SELECT '660e8400-e29b-41d4-a716-446655440001', h.id FROM bantora_hashtag h WHERE h.tag = 'irrigation'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_idea_hashtag (idea_id, hashtag_id)
SELECT '660e8400-e29b-41d4-a716-446655440002', h.id FROM bantora_hashtag h WHERE h.tag = 'health'
ON CONFLICT DO NOTHING;
INSERT INTO bantora_idea_hashtag (idea_id, hashtag_id)
SELECT '660e8400-e29b-41d4-a716-446655440003', h.id FROM bantora_hashtag h WHERE h.tag = 'railway'
ON CONFLICT DO NOTHING;
