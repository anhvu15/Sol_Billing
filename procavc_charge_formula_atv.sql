create or replace package procavc_charge_formula_atv 	is
	--
	-- get unit charge
	--
	function get_unit_charge(t_item_no in item_master.item_no%type ) return varchar2;

	function get_charge_quantity(t_item_no in item_master.item_no%type,
								 t_qty in number ) return number;
	
	function get_charge_amount( t_item_no in item_master.item_no%type,
								t_qty in number,								
								t_type in varchar2 :='MOV') return number;

end procavc_charge_formula_atv;
/
show err

