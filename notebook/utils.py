import requests
import json
import time
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from src.results_poller import poller


def reo_optimize(post):
    API_KEY = 'yOODa4jmZy1q3Wd6lkQcne6izi3nq2YSIIlCQkOg'
    root_url = 'https://developer.nrel.gov/api/reopt'
    post_url = root_url + '/v1/job/?api_key=' + API_KEY
    results_url = root_url + '/v1/job/<run_uuid>/results/?api_key=' + API_KEY

    resp = requests.post(url=post_url, json=post)

    if not resp.ok:
        print("Status code {}. {}".format(resp.status_code, resp.content))
    else:
        print("Response OK from {}.".format(post_url))
        run_id_dict = json.loads(resp.text)

        try:
            run_id = run_id_dict['run_uuid']
        except KeyError:
            msg = "Response from {} did not contain run_uuid.".format(post_url)

        return poller(url=results_url.replace('<run_uuid>', run_id))


def results_plots(results_dict):

    ylabel_fontsize = 24
    title_fontsize = 30
    tick_label_size = 20
    bar_data = dict()
    bar_stor_data = dict()
    for name, results in results_dict.items():

        # Initilize figure layout and assign axes
        fig = plt.figure(figsize=(21,5), constrained_layout=True)
        gs = gridspec.GridSpec(ncols=16, nrows=1, figure=fig)
        tech_stack = fig.add_subplot(gs[:,1:3])
        tech_stack.set_ylim(0, 400)
        tech_stack.tick_params(axis='both', labelsize=tick_label_size)

        tech_storage_stack = fig.add_subplot(gs[:,0])
        tech_storage_stack.set_ylim(0, 300)
        tech_storage_stack.tick_params(axis='both', labelsize=tick_label_size)

        loadAx = fig.add_subplot(gs[0,3:])
        loadAx.set_title(name, fontsize=title_fontsize)
        loadAx.set_ylabel('Power (kW)', fontsize=ylabel_fontsize)
        loadAx.tick_params(axis='both', labelsize=tick_label_size)

        # Plot base and total loads
        plotrange = 24*7
        bar_data[name] = dict()
        bar_stor_data[name] = dict()


        utility_load = results['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw']
        PV_load = results['outputs']['Scenario']['Site']['PV']['year_one_to_load_series_kw']
        BESS_load = results['outputs']['Scenario']['Site']['Storage']['year_one_to_load_series_kw']

        load = results['outputs']['Scenario']['Site']['LoadProfile']['year_one_electric_load_series_kw']
        loadAx.stackplot(range(plotrange),[utility_load[:plotrange], BESS_load[:plotrange], PV_load[:plotrange]],
                         labels = ['Utility', 'BESS', 'Solar PV'],
                         colors = ['tab:blue', 'maroon', 'tab:orange'])
        loadAx.legend(loc='upper left', fontsize=tick_label_size)

        pv_size = results['outputs']['Scenario']['Site']['PV']['size_kw']
        batt_kw = results['outputs']['Scenario']['Site']['Storage']['size_kw']
        batt_kwh = results['outputs']['Scenario']['Site']['Storage']['size_kwh']

        bar_names = ['Solar PV', 'Battery']
        vals = [pv_size, batt_kw]
        for bar_name, val in zip(bar_names, vals):
            bar_data[name][bar_name] = val

        tech_stack.tick_params(axis='x', labelrotation = 30)
        tech_stack.set_ylabel('Power (kW)', fontsize=ylabel_fontsize)
        tech_stack.bar(*zip(*bar_data[name].items()), color=['maroon', 'tab:orange'])

        bar_names = ['Battery']
        vals = [batt_kwh]
        for bar_name, val in zip(bar_names, vals):
            bar_stor_data[name][bar_name] = val

        tech_storage_stack.tick_params(axis='x', labelrotation = 30)
        tech_storage_stack.set_ylabel('Energy (kWh)', fontsize=ylabel_fontsize)
        tech_storage_stack.bar(*zip(*bar_stor_data[name].items()), color=['black'])

        plt.show()
        
def LCCbreakdown(results_fetched):
    pd.set_option('display.float_format', lambda x: '%.0f' % x)
    tariff_fin_keys = ['total_energy_cost_us_dollars',
                         'total_fixed_cost_us_dollars',
                         'total_demand_cost_us_dollars']

    labels = ['Capital Cost and O&M',
              'Energy Charge',
              'Fixed Cost',
              'Demand Charge']

    for scen in results_fetched.keys():

        pie_vals = OrderedDict()
        lcc = results_fetched[scen]['outputs']['Scenario']['Site']\
                                               ['Financial']['lcc_us_dollars']
        pie_vals[labels[0]] = results_fetched[scen]['outputs']['Scenario']['Site']\
                                               ['Financial']['net_capital_costs_plus_om_us_dollars']
        tariff = results_fetched[scen]['outputs']['Scenario']['Site']['ElectricTariff']

        tariff_costs = 0.0
        l = 1
        for k in tariff_fin_keys:
            tariff_costs += tariff[k]
            pie_vals[labels[l]] = tariff[k]
            l += 1

        tariff_costs -=tariff[u'total_export_benefit_us_dollars']

        df_results = pd.DataFrame(pie_vals, index = [1])

        print(scen, ": LCC = ", lc)
        print(df_results)

        plt.pie(list(pie_vals.values()), labels=labels, autopct='%1.1f%%',
            shadow=True, startangle=90)
        plt.show()
