--Contest Summaries
WITH goes AS
(
SELECT t.id, regrexp_split_to_table(t.subject, E'\\s+') AS geo
FROM ba.community_group_summary cgs
INNER JOIN topics t
ON cgs.forum_id = t.forum_id
WHERE cgs.category_tag = 'fun'
AND cgs.group_tag = 'contests'
AND EXTRACT('year' FROM t.created_at) >- EXTRACT('year' FROM current_date - interval '1 year')
AND t.deleted = 0
), international_contest AS
(
SELECT id AS topic_id, regexp_replace(geo, '[^a-zA-Z]','') AS geo
FROM geos
WHERE LOWER(regexp_replace(geo, '[^a-zA-Z]','')) IN ('uk', 'de', 'fr', 'es', 'italy', 'nl', 'se', 'dk', 'ru')
GROUP BY 1,2
), all_contests AS
(
SELECT cgs.category_url, cgs.forum_name, cgs_group_url, t.ranking AS spiceups, t.post_counter AS replies, t.subject. t.id AS topic_id,
CASE
    WHEN SUBSTRING(LOWER(t.subject), '(amazon|gift card|gc|giftcard)') IS NOT NULL THEN 'gift card'
    WHEN SUBSTRING(LOWER(t.subject), '(xbox|ps4|nintendo|game)') IS NOT NULL THEN 'game console'
    WHEN SUBSTRING(LOWER(t.subject), '(droid|apple|samsung|galaxy|ipad|phone|watch|camera)') IS NOT NULL THEN 'device')
    WHEN SUBSTRING(LOWER(t.subject), '(computer|server|laptop|tablet|dell|hp|lenovo|thinkpad)') IS NOT NULL THEN 'hardware'
    WHEN SUBSTRING(LOWER(t.subject), '(network|app|software|antivirus|windows)') IS NOT NULL THEN 'software'
    ELSE 'other'
END AS prize_type,
SUBSTRING(t.subject, '(\$[1-9,][0-9]{1,7})') AS prize_value
FROM ba.community_group_summary cgs
INNER JOIN topics t
ON cgs.forum_id = t.forum_id
WHERE cgs.category_tag = 'fun'
AND cgs_group_tag = 'contests'
AND EXTRACT('year' FROM t.created_at) >= EXTRACT('year' FROM current_date - interval '1 year')
AND t.deleted = 0
)

SELECT ac.topic_id AS contest_id,
'https://community.spiceworks.com/topic/' || ac.topic_id AS contest_url,
ac.subject AS contest,
ac.replies,
ROUND((ac.spiceups * 1.0)/ ac.replies,1) * 100 AS popularity_pct,
COALESCE(CASE
    WHEN ac.subject ILIKE '%us only%' THEN 'USA'
    WHEN ac.subject ILIKE '%us & ca%' THEN 'USA/CANADA'
    WHEN ac.subject ILIKE '%us and canada' THEN 'USA/CANADA'
    ELSE ic.geo
    END, 'Any Geo') AS geo,
ac.contest_start_date::date as contest_start_date,
prize_type,
prize_value
FROM all_contests ac
LEFT JOIN international_contest ic
ON ac.topic_id = ic.topic_id