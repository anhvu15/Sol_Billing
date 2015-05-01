DECLARE
  t_month varchar2(9) :='&t_month';
  cursor shipments_monthly is
  select a.order_no,a.order_suffix,a.plant_code,a.src_doc_id,a.ship_dt,a.ship_name,a.shipto_country_cd,A.soldto_attn,b.pick_stock_area as stock_area,sum(b.QTY_SHIPPED) as total
  from oehead a , oedetl b
  where a.order_no = b.order_no
  and a.order_suffix = b.order_suffix and
  a.cust_no= 'SOL005'
  and a.order_status IN ('S','V')
  and a.src_doc_id is not null
  and to_char(ship_dt,'MMYY') = t_month
  group by a.order_no,a.order_suffix,a.plant_code,a.src_doc_id,a.ship_dt,a.ship_name,a.shipto_country_cd,b.pick_stock_area,A.soldto_attn
  order by a.ship_dt,a.order_no;
  cursor shipment_charges is
  select a.order_no,a.run_date,a.qty,a.pallet_qty,a.code_apply,a.charge,b.first_price,b.second_price,b.um
  from fullfilment_monthly_charges a,fullfilment_billing_codes b
  where a.code_apply = b.code_apply and
  trunc(a.run_date) = trunc(sysdate)
  for update of charge;
  pallet_count number;
  t_ecom_flag varchar2(1);
  function get_full_pallets(t_order_no in oehead.order_no%type,t_order_suffix in oehead.order_suffix%type)                            
  return number
  as
    t_pallet number;    
  begin
    select count(*) into t_pallet
    from  oe_ship_container a
    where a.order_no = t_order_no
    and a.order_suffix = t_order_suffix
    and a.container_type = 'STD';
    return t_pallet;
  end; 
  function get_ecom_flag(t_stock_area in oedetl.pick_stock_area%type,t_plant_code in oedetl.plant_code%type)
  return varchar2
  as
    t_yn varchar2(1) :='N';
  begin
    if t_stock_area is not null then
      select ecom_flag into t_yn
      from avc_stock_areas
      where stock_area = nvl(t_stock_area,'XXXX')
      and plant_code = t_plant_code;
    end if;
    return t_yn;    
  end;
  function is_lithium_order(t_order_no in oehead.order_no%type,
                              t_order_suffix in oehead.order_suffix%type) return boolean
  is
    is_lithium boolean := false;
    t_count number;
    t_ship_to oehead.shipto_country_cd%type;
  begin
    select count(*)
    into t_count
    from oedetl b join item_master c on b.item_no = c.item_no
    where b.order_no = t_order_no
    and b.order_suffix = t_order_suffix
    and c.HAZMAT_FLAG = 'Y';
    if t_count > 0 then
      select shipto_country_cd
      into t_ship_to
      from oehead
      where order_no = t_order_no;
      if get_full_pallets(t_order_no,t_order_suffix) > 0 or nvl(t_ship_to,'USA') != 'USA' then
        is_lithium := true;
      end if;
    end if;
    return is_lithium;
  end;

  function is_b_to_c(t_order_no in oehead.order_no%type,
                      t_order_suffix in oehead.order_suffix%type) return boolean
  is
    
    t_inner_qty item_planning.inner_case_qty%type;    
    cursor c_item is    
    select item_no,sum(qty_shipped) total_shipped
    from oedetl
    where order_no = t_order_no
    and order_suffix = t_order_suffix
    group by item_no;
  begin
    for c in c_item loop
      select inner_case_qty
      into t_inner_qty
      from item_planning
      where item_no = c.item_no;
      if c.total_shipped > nvl(t_inner_qty,1) then
        return false;
      end if;
    end loop;
    return true;
  end is_b_to_c;
BEGIN
  dbms_output.enable(100000);
  delete from fullfilment_monthly_charges
  where trunc(run_date) = trunc(sysdate);
  for c in shipments_monthly loop
  t_ecom_flag :=get_ecom_flag(c.stock_area,c.plant_code);
    if t_ecom_flag = 'N' then
      if is_b_to_c(c.order_no,c.order_suffix) = false then
      insert into fullfilment_monthly_charges(order_no,run_date,qty,code_apply,ship_dt)
        values(c.order_no,trunc(sysdate),c.total,'BTBF',c.ship_dt); 
        if c.soldto_attn in ('KOHLS','NORDSTROM') then
          insert into fullfilment_monthly_charges(order_no,run_date,qty,code_apply,ship_dt)
          values(c.order_no,trunc(sysdate),c.total,'POVA',c.ship_dt); 
        end if;
      else
      insert into fullfilment_monthly_charges(order_no,run_date,qty,code_apply,ship_dt)
        values(c.order_no,trunc(sysdate),c.total,'BTCF',c.ship_dt);
      end if;
      pallet_count := get_full_pallets(c.order_no,c.order_suffix);
      if pallet_count > 0 then
        insert into fullfilment_monthly_charges(order_no,run_date,pallet_qty,code_apply,ship_dt)
          values(c.order_no,trunc(sysdate),pallet_count,'UPAL',c.ship_dt);
        insert into fullfilment_monthly_charges(order_no,run_date,pallet_qty,code_apply,ship_dt)
          values(c.order_no,trunc(sysdate),pallet_count,'VBOA',c.ship_dt);
        insert into fullfilment_monthly_charges(order_no,run_date,pallet_qty,code_apply,ship_dt)
          values(c.order_no,trunc(sysdate),pallet_count,'STRE',c.ship_dt);
        insert into fullfilment_monthly_charges(order_no,run_date,pallet_qty,code_apply,ship_dt)
          values(c.order_no,trunc(sysdate),pallet_count,'ENVP',c.ship_dt);
      end if;
    else
      insert into fullfilment_monthly_charges(order_no,run_date,qty,code_apply,ship_dt)
        values(c.order_no,trunc(sysdate),c.total,'ECOM',c.ship_dt);
    end if;
   if nvl(c.shipto_country_cd,'USA') != 'USA' then
    insert into fullfilment_monthly_charges(order_no,run_date,qty,code_apply,ship_dt)
        values(c.order_no,trunc(sysdate),c.total,'INTL',c.ship_dt);
   end if;
   if is_lithium_order(c.order_no,c.order_suffix) = true then
    insert into fullfilment_monthly_charges(order_no,run_date,qty,code_apply,ship_dt)
        values(c.order_no,trunc(sysdate),c.total,'LBDF',c.ship_dt);
   end if;
  end loop;
  for e in shipment_charges loop
    case e.um
      when 'SHIPMENT' then
        update fullfilment_monthly_charges
        set charge = e.first_price
        where current of shipment_charges;
      when 'PALLET' then
        update fullfilment_monthly_charges
        set charge = e.first_price * e.pallet_qty
        where current of shipment_charges;
      when 'UNIT' then
          if e.code_apply = 'BTBF' then
            update fullfilment_monthly_charges
            set charge = e.first_price * e.qty
            where current of shipment_charges;
          else
            update fullfilment_monthly_charges
            set charge = e.first_price  + (e.second_price*(e.qty-1))
            where current of shipment_charges;
          end if;
    end case;    
  end loop;
  commit;
  exception
    when others then
        rollback;
        dbms_output.put_line('Error: '||SQLCODE||'Error Message: '||substr(SQLERRM,1,80));
END;
/

