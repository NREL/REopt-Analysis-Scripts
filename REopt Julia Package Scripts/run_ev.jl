using Revise
using JSON
using Test
using JuMP
using Xpress
using HiGHS
using REopt
# ENV["NREL_DEVELOPER_API_KEY"] = ""

# EV testing notes
# Error when you force ElectricStorage to zero
# Charge energy from Storage and Grid to EV less than expected from EV charging requirements

input_data = JSON.parsefile("./scenarios/ev_new.json")

input_data["ElectricLoad"]["doe_reference_name"] = "FlatLoad"
input_data["ElectricLoad"]["annual_kwh"] = 0.0 * 8760.0
# Make a profile with diurnal off-peak and on-peak to get storage to charge EV instead of grid
input_data["ElectricTariff"]["tou_energy_rates_per_kwh"] = repeat(append!(repeat([0.01], 12), repeat([0.1], 12)), 365)
input_data["ElectricTariff"]["blended_annual_demand_rate"] = 0.0

# Set tech sizes
input_data["PV"]["min_kw"] = 0.0
input_data["PV"]["max_kw"] = 0.0
input_data["ElectricStorage"]["min_kw"] = 20.0
input_data["ElectricStorage"]["max_kw"] = 20.0
input_data["ElectricStorage"]["min_kwh"] = 100.0
input_data["ElectricStorage"]["max_kwh"] = 100.0

# Electric vehicles and EVSE
input_data["EVSupplyEquipment"]["max_num"] = [2]
input_data["EVSupplyEquipment"]["force_num_to_max"] = false
input_data["EVSupplyEquipment"]["power_rating_kw"] = [20.0]
cap_kwh = [100, 100]
ev_on_site_start_end = [[13, 24], [10, 14]]
# This is actually SOC_arrived, SOC_required
soc_used_off_site = [[0.2, 1.0], [0.3, 0.8]]
# Start with single/first EV
for i in eachindex(cap_kwh[1])
    append!(input_data["ElectricVehicle"], [Dict()])
    input_data["ElectricVehicle"][i]["energy_capacity_kwh"] = cap_kwh[i]
    # One entry for each quarter of the calendar year
    input_data["ElectricVehicle"][i]["ev_on_site_start_end"] = [ev_on_site_start_end[i] for _ in 1:4]
    input_data["ElectricVehicle"][i]["soc_used_off_site"] = [soc_used_off_site[i] for _ in 1:4]
end

s = Scenario(input_data)
inputs = REoptInputs(s)

# Xpress solver
m1 = Model(optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01, "OUTPUTLOG" => 0))
m2 = Model(optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01, "OUTPUTLOG" => 0))

# HiGHS solver
# m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
#     "output_flag" => false, "mip_rel_gap" => 0.01, "log_to_console" => false)
# )
# m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
#     "output_flag" => false, "mip_rel_gap" => 0.01, "log_to_console" => false)
# )

# results = run_reopt([m1,m2], inputs)
results = run_reopt(m1, inputs)

println("Storage to load kWh = ", round(sum(results["ElectricStorage"]["storage_to_load_series_kw"]), digits=0))
println("Storage to EV kWh = ", round(sum(results["EV1"]["on_site_storage_to_ev_series_kw"]), digits=0))
println("Grid to storage kWh = ", round(sum(results["ElectricUtility"]["electric_to_storage_series_kw"]), digits=0))
println("Grid to EV kWh = ", round(sum(results["ElectricUtility"]["electric_to_electricvehicle_series_kw"]), digits=0))