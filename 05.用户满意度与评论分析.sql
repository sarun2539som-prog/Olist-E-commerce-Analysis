/*
================================================================================
阶段 10：用户评分与物流时效关联分析

探究客户评价得分与实际配送天数之间的相关性。通过量化各评分等级下的平均送达时长
及占比，验证物流履约效率对用户满意度的直接影响，为提升平台 NPS（净推荐值）及
优化履约环节提供数据支持。
================================================================================
*/

select
    review_score as 评分
    ,count(review_score) as 评分数量
    ,round(count(review_score) / (
        select count(review_score)
        from olist_db.olist_order_reviews_dataset
    ), 2) as 评分占比
    ,round(avg(ord.delivery_days), 2) as 平均送达时间
from olist_db.olist_order_reviews_dataset re
join olist_db.orders_cleaned ord
    on re.order_id = ord.order_id
group by review_score
order by review_score desc;
/*
================================================================================
阶段 11：低分评价（差评）归因分析

通过对评论文本进行关键词聚类，识别导致 1-2 分低分评价的核心痛点。
结合物流时效指标验证评论内容的真实性，旨在区分“物流配送”、“产品质量”与“卖家服务”等
不同维度的服务缺陷，为平台治理及供应链质控提供定量的决策依据。
================================================================================
*/

select
    case
        when review_comment_message like '%entreg%' or review_comment_message like '%receb%' then '物流/未收到货'
        when review_comment_message like '%atraso%' or review_comment_message like '%prazo%' or review_comment_message like '%demor%' then '配送延迟'
        when review_comment_message like '%produt%' or review_comment_message like '%qualidad%' or review_comment_message like '%defect%' then '产品质量/货不对板'
        when review_comment_message like '%vendedor%' or review_comment_message like '%atendiment%' then '卖家服务'
        else '其他/无评论'
    end as 差评原因类型
    ,count(*) as 评价条数
    ,round(avg(ord.delivery_days), 1) as 该类平均送达天数
from olist_db.olist_order_reviews_dataset re
join olist_db.orders_cleaned ord
    on re.order_id = ord.order_id
where review_score <= 2
  and review_comment_message is not null
group by 1
order by 2 desc;
/*
================================================================================
阶段 12：品类维度下的差评率与物流时效交叉分析

将评价指标下钻至品类维度，通过对比各品类的差评率与平均配送时长，并引入双重排名机制，
识别受物流影响最严重的特定品类。旨在辅助判断差评驱动因素（产品质量 vs. 物流时效），
为品类管理提供精细化的治理优先级建议。
================================================================================
*/

select
    tra.product_category_name_english as 种类
    ,round(avg(review_score <= 2), 2) as 差评率
    ,round(avg(cl.delivery_days), 2) as 平均送达天数
    ,row_number() over(order by round(avg(review_score <= 2), 2) desc) as 差评率排名
    ,row_number() over(order by round(avg(cl.delivery_days), 2) asc) as 送达时效排名
from olist_db.olist_order_reviews_dataset sc
join olist_db.olist_order_items_dataset ord
    on sc.order_id = ord.order_id
join olist_db.olist_products_dataset pro
    on pro.product_id = ord.product_id
join olist_db.product_category_name_translation tra
    on tra.product_category_name = pro.product_category_name
join olist_db.orders_cleaned cl
    on cl.order_id = ord.order_id
group by 1
order by 差评率 desc;
/*
================================================================================
阶段 13：区域准时送达率与满意度关联分析

通过计算“预计送达”与“实际送达”的偏差，量化各州订单的准时送达率。旨在探究履约
承诺的达成情况如何影响区域用户评分，识别哪些地区的低分是由于“未达成物流预期”
导致的，为优化各区域的预期交付算法提供依据。
================================================================================
*/

with a as (
    select
        order_id
        ,customer_id
        -- 计算预计送达与实际送达之差（>=0 表示准时或提前）
        ,datediff(order_estimated_delivery_date, order_delivered_customer_date) as 天数
    from olist_db.orders_cleaned
    where order_status = 'delivered'
      and order_delivered_customer_date is not null
)

select
    customer_state as 省份
    ,avg(review_score) as 平均分数
    ,round(avg(case when 天数 >= 0 then 1 else 0 end), 2) as 准时送达率
from olist_db.olist_order_reviews_dataset re
join a da
    on da.order_id = re.order_id
join olist_db.olist_customers_dataset cus
    on cus.customer_id = da.customer_id
group by 1
order by 平均分数 desc;