-- I write a test to confirm if the count of deals in each stage is the same in my source table 'deal_pipeline_stages' and final_model 'sales_funnel'

WITH source as (
SELECT 
  stage_name,
  COUNT(*) as deal_count_source
FROM `accredible.deal_pipeline_stages`
WHERE stage_name IN ('Discovery', 'Qualified', 'Proof of Value', 'Proposal/Pricing', 'Procurement/Negotiation', 'Closed Lost', 'Closed Won')
GROUP By 1
),

-- Note that sales_funnel table is our final modelled table from and has been saved as a materialized view
destination as (SELECT 
  stage_name,
  COUNT(*) as deal_count_destination
FROM `accredible.sales_funnel`
GROUP By 1
)

SELECT 
  stage_name,
  s.deal_count_source,
  d.deal_count_destination
FROM source s
JOIN destination d USING(stage_name)

