/*
================================================================================
阶段 6：各品类物流成本（运费）分析

分析各品类的平均运费水平，识别高物流成本品类。
运费高低直接影响用户购买意愿及转化率，通过此分析可为产品定价策略、包邮政策制定
以及重物渠道优化提供数据支撑。
================================================================================
*/

select
    tra.product_category_name_english AS 产品名称,
    round(avg(freight_value), 2) AS 平均运费
from olist_db.olist_order_items_dataset ord
join olist_db.olist_products_dataset pro
    on ord.product_id = pro.product_id
join olist_db.product_category_name_translation tra
    on tra.product_category_name = pro.product_category_name
group by 1
order by 2 desc;
/*
================================================================================
阶段 7：各州物流成本与订单规模关联分析

通过对比各州的订单量与平均运费，评估地理位置对履约成本的影响。
利用排名函数识别运费洼地与高成本地区，帮助业务端判断订单规模是否产生了
规模效应，并为高成本地区的物流中转方案提供决策依据。
================================================================================
*/

select
    *
    ,row_number() over(order by 运费 asc) as 运费从低到高排名
from (
    select
        customer_state as 省份
        ,count(distinct o.order_id) as 订单数
        ,round(avg(freight_value), 2) as 运费
    from olist_db.olist_customers_dataset c
    join olist_db.orders_cleaned o
        on c.customer_id = o.customer_id
    join olist_db.olist_order_items_dataset y
        on y.order_id = o.order_id
    group by customer_state
) a
order by 订单数 desc;
/*
================================================================================
阶段 8：各州物流履约效率（时效）分析

评估各区域物流履约时效。通过计算平均配送时长，识别各省份的配送效率差异。
旨在发现物流瓶颈，为优化供应链路径、管理客户送达预期及调整物流服务等级提供
量化依据。
================================================================================
*/

select
    *
    ,row_number() over(order by 送达天数 asc) as 送达天数排名
from (
    select
        customer_state
        ,round(avg(delivery_days), 1) as 送达天数
        ,count(distinct o.order_id) as 订单数
    from olist_db.orders_cleaned d
    join olist_db.olist_customers_dataset c
        on c.customer_id = d.customer_id
    join olist_db.olist_order_items_dataset o
        on o.order_id = d.order_id
    where delivery_days is not null
    group by 1
) a
order by 订单数 desc;
