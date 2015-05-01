set echo off
set verify off
set heading off
set feedback off
set linesize 9999
set pages 0
set trimspool on
set colsep ','
spool c:\reports\sol005_fulfillment_billing.csv
select 'Order No, Plant Code, Shipment, Ship Date, Shipname, Ship To Country, Retailer ID, Stock Area, Ship Qty' from dual
/
select a.order_no,a.plant_code,a.src_doc_id,a.ship_dt,replace(a.ship_name,',',' '),a.shipto_country_cd,A.soldto_attn,b.pick_stock_area as stock_area,sum(b.QTY_SHIPPED) as total
from oehead a , oedetl b
where a.order_no = b.order_no
and a.order_suffix = b.order_suffix and
a.cust_no= 'SOL005'
and a.order_status IN ('S','V')
and a.src_doc_id is not null
and to_char(ship_dt,'MMYY') = '0415'
group by a.order_no,a.plant_code,a.src_doc_id,a.ship_dt,a.ship_name,a.shipto_country_cd,b.pick_stock_area,A.soldto_attn
order by a.ship_dt,a.order_no
/
spool off
/
undefine t_start_date
undefine t_end_date

  