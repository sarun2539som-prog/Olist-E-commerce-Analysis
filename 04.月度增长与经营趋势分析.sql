/*
================================================================================
阶段 9：月度经营核心指标趋势分析（GMV、订单量、客单价及环比增长）

通过时间序列维度监控经营动态。利用窗口函数（LAG）计算月度销售额、订单量及客单价
的环比增长率。此分析旨在量化业务增长趋势，识别业绩波动的周期性特征，评估营销
活动对客单价的拉动效果，为制定年度/季度经营目标提供基准数据。
================================================================================
*/

select
    left(order_purchase_timestamp, 7) as 月份
    ,round(sum(price), 2) as 销售额
    ,count(distinct cl.order_id) as 订单量
    ,round(sum(price), 2) / count(distinct cl.order_id) as 客单价
    -- 销售额环比增长率
    ,concat(round(((round(sum(price), 2) - lag(round(sum(price), 2), 1) over(order by left(order_purchase_timestamp, 7))) / lag(round(sum(price), 2), 1) over(order by left(order_purchase_timestamp, 7))) * 100, 2), '%') as 销售额增长率
    -- 订单量环比增长率
    ,concat(round(((count(distinct cl.order_id) - lag(count(distinct cl.order_id), 1) over(order by left(order_purchase_timestamp, 7))) / lag(count(distinct cl.order_id), 1) over(order by left(order_purchase_timestamp, 7))) * 100, 2), '%') as 订单量环比增长
    -- 客单价环比增长率
    ,concat(round((((round(sum(price), 2) / count(distinct cl.order_id)) - lag(round(sum(price), 2) / count(distinct cl.order_id), 1) over(order by left(order_purchase_timestamp, 7))) / lag(round(sum(price), 2) / count(distinct cl.order_id), 1) over(order by left(order_purchase_timestamp, 7))) * 100, 2), '%') as 客单价环比增长
from olist_db.orders_cleaned cl
join olist_db.olist_order_items_dataset ord
    on cl.order_id = ord.order_id
group by 1
order by 1 asc;