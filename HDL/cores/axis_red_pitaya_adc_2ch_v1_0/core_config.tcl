set display_name {AXI4-Stream Red Pitaya ADC 2CH}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter AXIS_TDATA_WIDTH {AXIS TDATA WIDTH} {Width of the M_AXIS data bus.}
core_parameter ADC_DATA_WIDTH {ADC DATA WIDTH} {Width of the ADC data bus.}

set bus [ipx::get_bus_interfaces -of_objects $core m0_axis]
set_property NAME M0_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces -of_objects $core m1_axis]
set_property NAME M1_AXIS $bus
set_property INTERFACE_MODE master $bus

set bus [ipx::get_bus_interfaces aclk]
set parameter [ipx::add_bus_parameter ASSOCIATED_BUSIF $bus]
set_property VALUE M0_AXIS:M1_AXIS $parameter
