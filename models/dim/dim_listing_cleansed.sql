with src_listings AS (
    SELECT * FROM {{ ref('src_listings') }}
)

SELECT 
    listing_id,
    listing_name,
    room_type,
    CASE
        -- minimum은 1이어야 함.
        WHEN minimum_nights = 0 THEN 1
        ELSE minimum_nights
    END AS minimum_nights,
    host_id,
    -- '$'문자 제거, numeric format으로 변환
    REPLACE(
        price_str,
        '$'
    ) :: NUMBER(
        10,
        2
    ) AS price,
    created_at,
    updated_at
FROM src_listings