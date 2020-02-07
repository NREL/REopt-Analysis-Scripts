import pandas as pd
import numpy as np
import os
import requests
import json
import copy
from src.logger import log


def set_default(d, k):
    """
    Try to set a default value from nested_input_definitions. If there is no default value, delete the key (k)
    :param d: dictionary
    :param k: key
    :return: None
    """
    try:
        if k not in ['tilt']:
            d[k] = d[k]['default']
        else:  # tilt default is "Site latitude" and is set to such in the api
            del d[k]

    except KeyError as e:
        if 'default' in e.args:
            log.debug("No default value exists for {}.".format(k))
            del d[k]
        else:
            raise e


def make_nested_dict(flat_dict, nested_dict, obj=None):
    """
    Use flat_dict, with key:value pairs from csv, and create a dict for posting to reopt api
    :param flat_dict: key:value pairs for one site
    :param nested_dict: nested_input_definitions from help endpoint
    :param obj: upper case key in nested_dict, represents reopt api class and used for '|' parameters from input csv
    :return:
    """

    for k, v in list(nested_dict.items()):

        piped_key = None
        if isinstance(obj, str):
            piped_key = obj + '|' + k

        if k[0].islower() and isinstance(v, dict):  # then this key represents an input value

            if k in flat_dict.keys():

                if pd.isnull(flat_dict[k]):  # empty cell in input csv file
                    set_default(nested_dict, k)
                else:  # use value from input csv
                    input_val = flat_dict[k]
                    # work-around for pd.df.to_dict() converting to numpy types, yargh.
                    if type(input_val) is np.int64:
                        input_val = int(input_val)
                    if isinstance(input_val, np.bool_):
                        input_val = bool(input_val)
                    nested_dict[k] = input_val

            elif piped_key in flat_dict.keys() and piped_key is not None:  # eg. PV|max_kw  NOTE: NO SPACES IN piped_key

                if pd.isnull(flat_dict[piped_key]):  # empty cell in input csv file
                    set_default(nested_dict, k)
                else:  # use value from input csv
                    input_val = flat_dict[piped_key]
                    # work-around for pd.df.to_dict() converting to numpy types, yargh.
                    if type(input_val) is np.int64:
                        input_val = int(input_val)
                    if isinstance(input_val, np.bool_):
                        input_val = bool(input_val)
                    nested_dict[k] = input_val

            else:  # no column in input csv
                set_default(nested_dict, k)

        if k in nested_dict.keys():  # k could be deleted in set_default if there is no default value
            if isinstance(nested_dict[k], dict):
                if any([isinstance(i, dict) for i in nested_dict[k].values()]):  # nested dict with definitions
                    make_nested_dict(flat_dict, nested_dict[k], obj=str(k))  # dig deeper into nested_dict

    return nested_dict


def add_load_profile_inputs(flat_dict, nested_dict, path_to_load_files="../inputs/load_profiles"):
    """
    If flat_dict has a "load_file" key (i.e. same column in csv file),
    then a custom load profile is added to the inputs (which is used by API even if other optional inputs are filled
    in, such as doe_reference_name and annual_kwh)
    :param flat_dict: inputs from site(s) data csv file
    :param nested_dict: nested_dict that has already passed through make_nested_dict (filled in single value inputs)
    :return: None
    """
    if "load_file" in flat_dict.keys():
        if not pd.isnull(flat_dict["load_file"]):  # case for some sites having custom load profiles
            fp = os.path.join(path_to_load_files, flat_dict["load_file"])
            load_profile = pd.read_csv(fp, header=None, squeeze=True).tolist()
            load_profile = [float(v) for v in load_profile]  # numpy floats are not JSON serializable

            assert len(load_profile) in [8760, 17520, 35040]

            nested_dict['Scenario']['Site']['LoadProfile']['loads_kw'] = load_profile

    else:
        log.info("Using built-in profile for Site number {}.".format(flat_dict['site_number']))


def multi_site_csv_parser(path_to_csv, api_url, API_KEY, n_sites=None):
    """
    Script to read a multi-sites input csv file and parse it into dictionaries for passing to the API.
    :param path_to_csv: path to csv file containing rows for each site and column headers.
    :param n_sites: default=None. If integer value is passed then only that many sites will be processed.
    :return: list of dictionaries, with length equal to n_sites, which can be posted to API. Additional keys may be
    added for creating output summary csv.


    TODO: [ ] pass start row and end row for running scenarios.
    """

    df = pd.read_csv(path_to_csv)

    if isinstance(n_sites, int):
        df = df.iloc[:n_sites]

    input_definitions = json.loads(requests.get(api_url + '/help?API_KEY=' + API_KEY).content)

    posts = []
    for i in range(len(df)):
        nested_dict = copy.deepcopy(input_definitions)

        site_inputs = df.iloc[i].to_dict()
        posts.append(make_nested_dict(site_inputs, nested_dict))

        add_load_profile_inputs(site_inputs, posts[-1], path_to_load_files=os.path.join(path_to_csv[:path_to_csv.index(os.sep)], 'load_profiles'))

        posts[i]['Scenario']['Site']['Wind'] = {'max_kw': 0}  # hack for Wind not in help endpoint

    return posts

