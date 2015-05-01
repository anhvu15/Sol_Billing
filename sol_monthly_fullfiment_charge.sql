select *
from(select order_no,TRUNC(ship_dt) as ship_date,code_apply,charge from fullfilment_monthly_charges where  TRUNC(RUN_DATE) = TRUNC(SYSDATE))
pivot (sum(charge) as charge for code_apply in ('BTBF' AS "B TO B",'BTCF' AS "B TO C",'ECOM' AS "ECOM",'INTL' AS "INTERNATIONAL ORDERS",'POVA' AS "PROCESS VARIATION",'ENVP' AS "PALLET EVENLOP",'UPAL' AS "USED PALLET",
       'VBOA' AS "V BOARDS",'STRE' AS "STRETCH WRAP",'LBDF' AS "LITHIUM BATTERY HANDLING"))
ORDER BY ship_date,order_no;