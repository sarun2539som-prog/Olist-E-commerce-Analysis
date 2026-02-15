/*
================================================================================
阶段 14：基于 RFM 模型的用户价值分层分析

本模块利用 RFM 模型对用户进行精细化分层。通过 Recency（最近一次消费时间）、
Frequency（消费频率）和 Monetary（消费金额）三个维度，利用 ntile(5) 进行五分位
打分量化。旨在识别“核心价值客户”与“重点挽留客户”，为差异化的营销资源分配、
客户生命周期管理（LTV）及精准触达策略提供建模支撑。
================================================================================
*/

with rfm_scores as (
    select
        customer_unique_id
        -- R轴：计算距今最后一次消费天数
        ,datediff((select max(order_purchase_timestamp) from olist_db.orders_cleaned), max(order_purchase_timestamp)) as r_raw
        -- F轴：累计订单量
        ,count(distinct pr.order_id) as f_raw
        -- M轴：累计消费金额
        ,sum(pr.price) as m_raw
        -- 使用五分位数进行打分
        ,ntile(5) over(order by datediff((select max(order_purchase_timestamp) from olist_db.orders_cleaned), max(order_purchase_timestamp)) desc) as r_score
        ,ntile(5) over(order by count(distinct pr.order_id) asc) as f_score
        ,ntile(5) over(order by sum(pr.price) asc) as m_score
    from olist_db.orders_cleaned cl
    join olist_db.olist_customers_dataset cus on cus.customer_id = cl.customer_id
    join olist_db.olist_order_items_dataset pr on pr.order_id = cl.order_id
    group by 1
)
select
    *
    ,case
        when r_score >= 4 and (f_score + m_score)/2 >= 4 then '核心价值客户'
        when r_score >= 4 and (f_score + m_score)/2 < 4 then '重要发展客户'
        when r_score < 4 and (f_score + m_score)/2 >= 4 then '重点挽留客户'
        else '一般/流失客户'
    end as 客户等级
from rfm_scores
order by m_raw desc;