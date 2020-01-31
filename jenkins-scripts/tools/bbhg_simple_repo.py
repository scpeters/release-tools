#!/usr/bin/env python3
import json, sys, urllib.parse, urllib.request

if len(sys.argv) != 2:
    print('need to specify the owner name', file=sys.stderr)
    exit()
owner = sys.argv[1]
query = '(scm="hg" AND has_issues=false AND has_wiki=false)'

escaped_url = "https://bitbucket.org/api/2.0/repositories/%s" % \
    (owner + '?q=' + urllib.parse.quote_plus(query))
# print(escaped_url)
# print(urllib.parse.unquote_plus(escaped_url))
print("Bitbucket HG repositories without issues, wiki or pull requests")

pull_request_states = [ \
  'MERGED', \
  'OPEN', \
  'SUPERSEDED', \
  'DECLINED']
repo_list = []
j = {}
j['next'] = escaped_url

while 'next' in j:
    response = urllib.request.urlopen(j['next'])
    j = json.loads(response.read().decode('utf-8'))
    for v in j["values"]:
        has_pulls = False
        for s in pull_request_states:
            url = v["links"]["pullrequests"]["href"] + "?state=" + s
            # print("checking " + url)
            pr_response = urllib.request.urlopen(url)
            pr_j = json.loads(pr_response.read().decode('utf-8'))
            if pr_j["size"] > 0:
                has_pulls = True
                break
        if not has_pulls:
            repo_list.append(v["links"]["html"]["href"])

repo_list.sort()
for r in repo_list:
    print(r)
