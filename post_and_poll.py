import requests
import json
import ast
from logger import log
from results_poller import poller

results_file = 'results.json'
root_url = 'http://127.0.0.1:8000'
post_url = root_url + '/v1/job/'
results_url = root_url + '/v1/job/<run_uuid>/results'

post = json.load(open('Scenario_POST.json'))

session = requests.Session()
session.verify = False
resp = session.post(url=post_url, json=post)

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

    results = poller(url=results_url.replace('<run_uuid>', run_id))

    with open(results_file, 'wb') as fp:
        json.dump(obj=results, fp=fp)

    log.info("Saved results to {}".format(results_file))
