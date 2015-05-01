set echo off
set verify off
set feedback off
set linesize 9999
set pages 0
set trimspool on
set colsep ','
spool c:\reports\sol_cancel_charge.csv
select 'ORDER NO, ORDER STATUS, ORDER DATE,SHIPMENT NO, SHIP NAME, PICK LIST TIME, J STATUS TIME, CANCEL TIME, ITEM NO,ECOM, TOTAL UNIT,BILLING AMOUNT' FROM DUAL
/
select a.order_nO,a.order_status||','||TO_CHAR(a.ORDER_DATE,'MM-DD-YY')||','||a.src_doc_id||','||replace(a.SHIP_NAME,',',' ')||','||to_char(min(b.ACTION_DT),'MM-DD-YY HH24: MI') ||','||to_char(min(d.ACTION_DT),'MM-DD-YY HH24: MI') ||','|| to_char(min(c.ACTION_DT),'MM-DD-YY HH24: MI')||','||A.ITEM_NO||','||procavc_charge_formula_atv.is_ecom_order(a.order_no,a.order_suffix)||','||A.TOTAL||','|| 
case procavc_charge_formula_atv.is_ecom_order(a.order_no,a.order_suffix) when 'N' then 0.34 * A.TOTAL else 2.25 + ((A.TOTAL -1)* 0.60) end
from (SELECT x.order_no,x.order_suffix,x.order_date,X.order_status,x.src_doc_id,x.ship_name,y.item_no,sum(y.QTY_ORDER) TOTAL
from oehead x join oedetl y on x.order_no = y.order_no and x.order_suffix = y.order_suffix
where X.order_status = 'X'
and X.cust_no = 'SOL005'
and to_char(X.order_date,'MMYY') = '0415'
group by x.order_no,x.order_suffix,X.order_status,x.order_date,x.ship_name,y.item_no,x.src_doc_id) a, oe_tracking b,oe_tracking c,oe_tracking d
where  a.order_no = d.order_no(+)
and a.order_suffix= d.order_suffix(+)
and d.order_status(+) = 'J'
and a.order_no= b.order_no
and a.order_suffix= b.order_suffix
and a.order_no = c.order_no
and a.ORDER_SUFFIX = c.ORDER_SUFFIX
and c.order_status = 'X'
and b.TRACK_CD = 'PICKPRINT'
group by  a.order_no,a.order_suffix,a.order_status,a.ORDER_DATE,a.SHIP_NAME,A.ITEM_NO,A.TOTAL,a.src_doc_id
having min(c.ACTION_DT) - min(b.ACTION_DT) > 0
order by a.order_date, a.order_no,a.item_no
/
spool off
/



