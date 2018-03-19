import requests
import json
import ast
from logger import log
from results_poller import poller

results_file = 'results.json'

root_url = 'https://developer.nrel.gov/reopt'
post_url = root_url + '/api/v1/'
results_url = root_url + '/results/'

post = json.load(open('POST.json'))

resp = requests.post(post_url, json=post)

if not resp.ok:
    log.error("Status code {}. {}".format(resp.status_code, resp.content))
else:
    log.info("Response OK from {}.".format(post_url))

    run_id_dict = ast.literal_eval(resp.content)

    try:
        run_id = run_id_dict['run_uuid']
    except KeyError:
        msg = "Response from {} did not contain run_uuid.".format(post_url)
        log.error(msg)
        raise KeyError(msg)

    results = poller(url=results_url, run_id=run_id)
    json.dump(results, results_file)
