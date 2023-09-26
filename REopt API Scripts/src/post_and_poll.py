import requests
import json
from src.logger import log
from src.results_poller import poller, poller_v3


def get_api_results(post, API_KEY, api_url, results_file='results.json', run_id=None):
    """
    Function for posting job and polling results end-point
    :param post:
    :param results_file:
    :param API_KEY:
    :param api_url:
    :return: results dictionary / API response
    """

    if run_id is None:
        run_id = get_run_uuid(post, API_KEY=API_KEY, api_url=api_url)

    if run_id is not None:

        results_url = api_url + '/job/<run_uuid>/results/?api_key=' + API_KEY
        if "stable" in results_url or "v3" in results_url:
            results = poller_v3(url=results_url.replace('<run_uuid>', run_id))
        else: # for v1 and v2
            results = poller(url=results_url.replace('<run_uuid>', run_id))

        with open(results_file, 'w') as fp:
            json.dump(obj=results, fp=fp)

        log.info("Saved results to {}".format(results_file))
    else:
        results = None
        log.error("Unable to get results: no run_uuid from POST.")

    return results


def get_run_uuid(post, API_KEY, api_url):
    """
    Function for posting job
    :param post:
    :param API_KEY:
    :param api_url:
    :return: job run_uuid
    """
    post_url = api_url + '/job/?api_key=' + API_KEY
    resp = requests.post(post_url, json=post)
    run_id = None
    if not resp.ok:
        log.error("Status code {}. {}".format(resp.status_code, resp.content))
    else:
        log.info("Response OK from {}.".format(post_url))

        run_id_dict = json.loads(resp.text)

        try:
            run_id = run_id_dict['run_uuid']
        except KeyError:
            msg = "Response from {} did not contain run_uuid.".format(post_url)
            log.error(msg)

    return run_id


if __name__ == '__main__':
    """
    In case just need to re-save json response
    """
    run_uuid = "my_run_id"
    file_name = "my_results.json"
    api_url = 'https://developer.nrel.gov/api/reopt/stable'
    API_KEY = "DEMO_KEY"

    results = get_api_results(post={}, API_KEY=API_KEY, run_id=run_uuid, results_file=file_name, api_url=api_url)
