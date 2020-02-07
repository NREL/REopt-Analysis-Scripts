import os
from src.multi_site_inputs_parser import multi_site_csv_parser
from src.parse_api_responses_to_csv import parse_responses_to_csv_with_template
from src.post_and_poll import get_api_results
from src.parse_api_responses_to_excel import parse_api_responses_to_excel

"""
Change these values
"""
##############################################################################################################
API_KEY = 'my_API_KEY'  # REPLACE WITH YOUR API KEY
inputs_path = os.path.join('inputs')
outputs_path = os.path.join('outputs')
output_template = os.path.join(outputs_path, 'results_template.csv')
output_file = os.path.join(outputs_path, 'results_summary.csv')
##############################################################################################################

server = 'https://developer.nrel.gov/api/reopt/v1'

path_to_inputs = os.path.join(inputs_path, 'scenarios.csv')
list_of_posts = multi_site_csv_parser(path_to_inputs, api_url=server, API_KEY=API_KEY)

responses = []

for post in list_of_posts:
    responses.append(get_api_results(
        post, results_file=os.path.join(outputs_path, post['Scenario']['description'] + '.json'),
        api_url=server, API_KEY=API_KEY)
    )

"""
Two options for making a summary of scenarios:
1. Write to a csv using a template with column headers for desired summary keys (scalar values only)
2. Write all inputs, outputs, and dispatch to an Excel spreadsheet
"""
parse_responses_to_csv_with_template(csv_template=output_template, responses=responses, output_csv=output_file, input_csv=path_to_inputs,
                                     n_custom_columns=2)

parse_api_responses_to_excel(responses, spreadsheet='results_summary.xlsx')