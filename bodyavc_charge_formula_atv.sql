create or replace package body procavc_charge_formula_atv
	

is
	g_default_unit item_price.item_price_group%type := 'EA';
	g_unit_mov_price number := 0.32;
	g_cust_no item_master.account_class%type :='SOL005';
	g_box_mov_price number :=0.32;
	g_pallet_mov_price number :=0.32;
	g_unit_rec_price number := 0.10;
	g_box_rec_price number :=0.10;
	g_pallet_rec_price number :=0.10;
	g_plant_code plant_master.plant_code%type := '45';
	function get_unit_charge(t_item_no in item_master.item_no%type ) return varchar2
	is
		t_unit_code plant_master.unit_code%type;
		t_plant_code plant_master.plant_code%type;
		t_unit item_price.item_price_group%type;
	begin
		
		select b.item_price_group into t_unit
		from  item_master a, item_price b
		where a.item_no = b.item_no
		and a.stock_um = b.sales_um
		and a.account_class = g_cust_no
		and b.unit_code = '100'
		and b.plant_code = g_plant_code
		and b.item_no = t_item_no;
		return nvl(t_unit,g_default_unit);
		exception
			when others then
				return g_default_unit;

	end get_unit_charge;

	function get_charge_quantity(t_item_no in item_master.item_no%type,
								 t_qty in number ) return number
	is
		t_case_qty item_planning.case_qty%type;
		t_cases_per_pallet item_planning.cases_per_pallet%type;
		t_calculated_qty number;
		t_unit item_price.item_price_group%type;
	begin
		select case_qty,cases_per_pallet
		into t_case_qty,t_cases_per_pallet
		from item_planning
		where item_no = t_item_no;
		if t_case_qty is null or t_case_qty = 0 then
			t_case_qty := 1;
		end if;
		if t_cases_per_pallet is null or t_cases_per_pallet = 0 then
			t_cases_per_pallet :=1;
		end if;
		t_unit := get_unit_charge(t_item_no);
		case t_unit
			when 'BX' then
				t_calculated_qty := ceil(t_qty / t_case_qty);
			when 'PL' then
				t_calculated_qty :=ceil((ceil(t_qty / t_case_qty )) / t_cases_per_pallet);
			else
				t_calculated_qty := t_qty;
		end case;
		return t_calculated_qty;
	end;

	
	function get_charge_amount(t_item_no in item_master.item_no%type,
								t_qty in number,								
								t_type in varchar2 :='MOV') return number
	is
		t_price number;
		t_unit item_price.item_price_group%type;
	begin
		t_unit := get_unit_charge(t_item_no);
		case t_type 
		when 'REC' then
			case t_unit
				when 'BX' then
					t_price := g_box_rec_price;
				when 'PL' then
					t_price	:= g_pallet_rec_price;
				else
					t_price := g_unit_rec_price;
			end case;
		else
			case t_unit
				when 'BX' then
					t_price := g_box_mov_price;
				when 'PL' then
					t_price	:= g_pallet_mov_price;
				else
					t_price := g_unit_mov_price;
			end case;
		end case;
			return t_qty*t_price;
	end;
end procavc_charge_formula_atv;
/
show err
/
