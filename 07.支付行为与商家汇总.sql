/*
================================================================================
阶段 15：支付方式与分期行为分布分析

通过分析支付渠道分布及分期期数偏好，还原用户的财务支付习惯。
这一维度能够揭示高客单价商品的成交动力（如信用卡分期依赖度），帮助业务端优化
支付结算流程、评估财务手续费成本，并为精准营销中的分期免息策略提供数据依据。
================================================================================
*/

select
    payment_type as 支付方式
    ,payment_installments as 支付分期
    ,round(sum(payment_value), 2) as 销售额
from olist_db.olist_order_payments_dataset
group by 1, 2
order by 3 desc;
/*
================================================================================
阶段 16：供方市场（卖家端）地理分布分析

从供应侧识别核心卖家区域。通过分析卖家省份销售额分布，评估平台供需匹配的地域
特征。这对于优化区域招商策略、提升物流集散效率以及平衡区域供需关系具有核心
参考价值。
================================================================================
*/

select
    seller_state as 卖家省份
    ,round(sum(price), 2) as 销售额
from olist_db.olist_sellers_dataset se
join olist_db.olist_order_items_dataset ord
    on se.seller_id = ord.seller_id
group by 1
order by sum(price) desc;