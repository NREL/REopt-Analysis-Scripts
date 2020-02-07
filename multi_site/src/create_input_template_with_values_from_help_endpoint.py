import requests
import json
import pandas as pd
from src.logger import log
from collections import OrderedDict
API_KEY = 'DEMO_KEY'
api_url = 'https://developer.nrel.gov/api/reopt/v1'


def set_default(nested_dict, flat_dict, k, piped_key):
    """
    Try to set a default value from nested_input_definitions. If there is no default value, set to None
    :param d: dictionary
    :param k: key
    :return: None
    """
    if piped_key.startswith("Scenario"):
        piped_key = piped_key.lstrip("Scenario|")
    try:
        if k not in ['tilt']:
            flat_dict[piped_key] = nested_dict[k]['default']
        else:  # tilt default is "Site latitude" and is set to such in the api
            flat_dict[piped_key] = None

    except KeyError as e:
        if 'default' in e.args:
            log.debug("No default value exists for {}. Set value to None".format(k))
            flat_dict[piped_key] = None
        else:
            raise e


def flatten_nested_dict(nested_dict, flat_dict=None, obj=None):
    """
    recursive function for converting a nested dictionary into a flat one using the piped key convention from
    multi_site_inputs_parser.py
    :param nested_dict:
    :param flat_dict:
    :param obj:
    :return:
    """
    if flat_dict is None:  # for initial call to flatten_nested_dict
        flat_dict = OrderedDict()

    for k, v in list(sorted(nested_dict.items())):

        piped_key = None
        if isinstance(obj, str):
            piped_key = obj + '|' + k

        if k[0].islower() and isinstance(v, dict):

            if piped_key is not None:
                set_default(nested_dict, flat_dict, k, piped_key)

        if k in nested_dict.keys():  # k could be deleted in set_default if there is no default value
            if isinstance(nested_dict[k], dict):
                if any([isinstance(i, dict) for i in nested_dict[k].values()]):  # nested dict with definitions
                    flatten_nested_dict(nested_dict[k], flat_dict, obj=str(k))  # dig deeper into nested_dict
    return flat_dict


def create_input_template_with_values_from_help_endpoint(api_url, API_KEY):
    input_definitions = json.loads(requests.get(api_url + '/help?API_KEY=' + API_KEY).content)
    flat_dict = flatten_nested_dict(input_definitions)
    # fill in enough values to run an example
    flat_dict["site_number"] = 1
    flat_dict["description"] = "test site"
    flat_dict["Site|latitude"] = 34
    flat_dict["Site|longitude"] = -118
    flat_dict["ElectricTariff|urdb_label"] = "5a3821035457a32645d2dd80"
    flat_dict["LoadProfile|doe_reference_name"] = "LargeOffice"
    flat_dict["LoadProfile|annual_kwh"] = 1000000
    flat_dict.move_to_end("site_number", last=False)
    df = pd.DataFrame(flat_dict, index=[1])
    df.to_csv("all_api_inputs.csv", index=False)


if __name__ == "__main__":
    create_input_template_with_values_from_help_endpoint(api_url, API_KEY)