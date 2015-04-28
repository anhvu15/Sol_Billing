set echo off
set verify off
set heading off
set feedback off
Set linesize 9999
set pages 0
set trimspool on
accept t_month prompt 'Enter the month (MMYY): '
spool c:\reports\SOL005_RECEIVING_MONTH_'&t_month'.csv
select 'Part Number,Description,Item Type Code,Quantity Expected, Received Date,PO Reference, Cust Reference,Received Quantity,Case Qty,Case Pallet,Billing Unit,Billing Qty,Billing Amount' from dual
/
select to_char('="'||b.item_no||'"')||','||REPLACE(b.description,',',' ')||','||REPLACE(c.description,',','')||','||to_char((e.qty_ordered + a.trans_qty) - e.qty_received)
||','||a.trans_date||','||a.ref_order||','||d.v_contact||','||nvl(a.trans_qty,0)||','||f.case_qty||','||f.cases_per_pallet||','||
procavc_charge_formula_atv.get_unit_charge(b.item_no)||','||procavc_charge_formula_atv.get_charge_quantity(b.item_no,nvl(a.trans_qty,0)) ||','||
procavc_charge_formula_atv.get_charge_amount(b.item_no,procavc_charge_formula_atv.get_charge_quantity(b.item_no,nvl(trans_qty,0)),'REC')
from item_trans_log a,item_master b,product_groups c, po_header d, po_detail e,item_planning f
where a.item_no=b.item_no
and a.item_no = f.item_no
and b.product_Group=c.product_group
and b.account_class='SOL005'
and a.trans_type = 'E'
and b.status_flag !='I'
and to_char(trans_date,'MMYY') = '&t_month'
and a.ref_order = d.po_no
and d.po_no = e.po_no
and e.item_no = a.item_no
order by b.item_no,a.trans_date
/
spool off
undefine t_month
EXIT
