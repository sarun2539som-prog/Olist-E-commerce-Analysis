/*
================================================================================
阶段 3：业务现状探索 —— 核心品类贡献度分析

在深入进行细分维度的体验诊断前，首先通过对全站营收结构的分析，识别出平台的核心基本盘。
本模块通过聚合各品类的累计成交总额 (GMV)，筛选出 Top 10 核心品类，
旨在确保后续的物流时效优化与体验诊断建议能优先覆盖高价值业务板块。
================================================================================
*/
select
product_category_name name
,round(sum(price),2) 销售额
from olist_db.products_cleaned clean
join olist_db.olist_order_items_dataset pro
on pro.product_id=clean.product_id
group by 1
order by 销售额 desc
limit 10
/*
================================================================================
阶段 4：区域市场销售分布分析

在明确了核心品类贡献后，本模块将分析维度转向地理空间分布。通过统计各州（State）的累计销售额，
识别平台的核心市场区域。这一步对于优化物流资源配置以及制定差异化的
区域营销策略至关重要，旨在确保高价值地区的履约效率与市场渗透率。
================================================================================
*/

select sum(ord.price)
,diqu.customer_state
from olist_db.olist_order_items_dataset ord
join olist_db.orders_cleaned clean
on clean.order_id=ord.order_id
join olist_db.olist_customers_dataset diqu
on diqu.customer_id=clean.customer_id
group by diqu.customer_state
order by sum(price) desc
limit 5;

/*
================================================================================
阶段 5：核心市场（SP-圣保罗州）品类偏好下钻

针对营收贡献最高的 SP 州进行品类下钻，验证局部偏好与全站大盘的差异。
旨在辅助业务端判断是否需要实施差异化选品及本地化仓储策略，最大化核心市场效应。
================================================================================
*/

select
b.product_category_name
,round(sum(a.price) ,2) 销售额
from olist_db.olist_order_items_dataset a
join olist_db.products_cleaned b
on a.product_id=b.product_id
where order_id in
      (select order_id
       from olist_db.orders_cleaned
       where customer_id in
             (select customer_id
              from olist_db.olist_customers_dataset
              where customer_state = 'SP'))
group by 1
order by round(sum(a.price) ,2) desc
limit 5;

