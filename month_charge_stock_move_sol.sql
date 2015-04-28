set echo off
set verify off
set heading off
set feedback off
Set linesize 9999
set pages 0
set trimspool on
set colsep ','
SET PAGES 0
accept month_charge prompt 'Enter Month (MMYY): '
spool c:\reports\sol005_stock_move_'&month_charge'.csv
select 'MOVE_TIMESTAMP,CLIENT_SKU,DESCRIPTION,LOCATION_TYPE,FROM_STOCK_AREA,FROM_BIN_LOC,TO_STOCK_AREA,TO_BIN_LOC,NOTES,REASON_CODE,REASON_DESC,REFERENCE,UNITS_MOVE,CASE QTY,CASES PALLET,GROUP_UM,BILLING_QTY,BILLING_AMOUNT' from dual
/
select nvl(a.TRANS_TIMESTAMP,to_char(a.trans_date,'MM-DD-RR'))||',="'||to_char(a.item_no)||'",'||replace(a.DESCRIPTION,',',' ')||','||a.LOCATION_TYPE||','||a.CLIENT_FROM_STOCK_AREA||','||
a.FROM_BIN_LOC||','||a.CLIENT_TO_STOCK_AREA||','||a.TO_BIN_LOC||','||a.NOTES||','||a.REASON_CODE||','||a.REASON_DESC||','||a.REF_REMARK||','||a.trans_qty||','||b.case_qty||','||b.cases_per_pallet||','||
procavc_charge_formula_atv.get_unit_charge(a.item_no) ||','||procavc_charge_formula_atv.get_charge_quantity(a.item_no,a.trans_qty)||','||
CASE WHEN a.CLIENT_FROM_STOCK_AREA  IN('AVC','AVC-BTC','AVC-MRB') AND a.CLIENT_TO_STOCK_AREA IN('AVC','AVC-BTC','AVC-MRB') AND a.CLIENT_TO_STOCK_AREA !=a.CLIENT_FROM_STOCK_AREA AND a.REASON_CODE != 'NO CHARGE' THEN  procavc_charge_formula_atv.get_charge_amount(a.item_no,procavc_charge_formula_atv.get_charge_quantity(a.item_no,a.trans_qty)) ELSE 0 END 
from AVC_CLIENT_STOCK_MOVE_VW a,item_planning_vw b																					
where a.item_no = b.item_no
and a.cust_no = 'SOL005'
and to_char(trunc(a.trans_date),'MMYY') =upper('&month_charge')
order by to_char(a.trans_date), a.item_no, a.trans_qty
/
spool off
/
undefine month_charge






