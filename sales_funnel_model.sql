-- I'll break my pipeline into three stages

-- For the first stage, I'll filter the deal_pipeline_stages table to only include stages I am interested in for my report, also I'll add an additional field called stage_index. This field becomes important in creating the visuals/charts as it allows me order the stages in the correct order

-- For the second stage, I'll join the 'deals' table to the 'deal_pipeline_stages'table to extract the corresponding value of a deal, the date it was closed, and the deal source

-- For the third and final stage, I'll just query all the records in the second stage  

WITH deal_pipeline AS (
  SELECT  
      deal_id,
      stage_created_at,
      stage_name,
      -- create stage_index column to help me order the stages
      CASE 
        WHEN stage_name = 'Discovery' THEN 1
        WHEN stage_name = 'Qualified' THEN 2
        WHEN stage_name = 'Proof of Value' THEN 3
        WHEN stage_name = 'Proposal/Pricing' THEN 4
        WHEN stage_name = 'Procurement/Negotiation' THEN 5
        WHEN stage_name = 'Closed Lost' THEN 6
        WHEN stage_name = 'Closed Won' THEN 7
      END as stage_index

    FROM `accredible.deal_pipeline_stages`
    -- add filter to only include stages necessary for the funnel
    WHERE stage_name IN 
        ('Discovery', 'Qualified', 'Proof of Value', 'Proposal/Pricing', 'Procurement/Negotiation', 'Closed Lost', 'Closed Won')
),

-- The sales_funnel_model CTE contains all the records from the deal_pipeline CTE, and the corresponding deal amount, close_date and deal_source_type from the deals table

sales_funnel_model AS (SELECT
  dp.*,
  -- Not all deal_id's present in the 'deal_pipeline_stages' table are present in the 'deals' table so I replace cases where amount will be NULL to Zero (0)
  CASE WHEN d.amount_in_home_currency IS NULL THEN 0 ELSE d.AMOUNT_IN_HOME_CURRENCY END  as deal_amount,

  -- Since some deal_id's are not present in the 'deals' table they won't have a value in the close_date column. So I use a window function (MAX) to replace instances where the close_date will otherwose be NULL with the most recent stage_created_at for each deal_id. This way, I have a value for all records in the close_date column  
  CASE WHEN d.CLOSE_DATE IS NOT NULL THEN d.close_date ELSE MAX(stage_created_at) OVER (PARTITION BY deal_id) END as close_date,

  -- For instances where the deal_source_type will be null, I replace this with None
  CASE WHEN d.deal_source_type IS NULL THEN 'None' ELSE d.DEAL_SOURCE_TYPE END as deal_source_type 
FROM deal_pipeline dp
LEFT JOIN `accredible.deals` d USING(deal_id)
ORDER BY 1,2
)

SELECT 
  *
FROM sales_funnel_model

