#!/usr/bin/env python3
import json, sys, urllib.parse, urllib.request

if len(sys.argv) != 2:
    print('need to specify the owner name', file=sys.stderr)
    exit()
owner = sys.argv[1]
# query = '(scm="hg" AND has_issues=false AND has_wiki=false)'
query = '(scm="hg")'

escaped_url = "https://bitbucket.org/api/2.0/repositories/%s" % \
    (owner + '?q=' + urllib.parse.quote_plus(query))
# print(escaped_url)
# print(urllib.parse.unquote_plus(escaped_url))
print("# Bitbucket HG repositories")
print("| Repository | pull requests | issues | wiki |")
print("|--|--|--|--|")

pull_request_states = [ \
  'MERGED', \
  'OPEN', \
  'SUPERSEDED', \
  'DECLINED']
repo_pullIssueWiki = {}
j = {}
j['next'] = escaped_url

while 'next' in j:
    response = urllib.request.urlopen(j['next'])
    j = json.loads(response.read().decode('utf-8'))
    for v in j["values"]:
        pulls = 0
        try:
            for s in pull_request_states:
                url = v["links"]["pullrequests"]["href"] + "?state=" + s
                # print("checking " + url)
                pr_response = urllib.request.urlopen(url)
                pr_j = json.loads(pr_response.read().decode('utf-8'))
                pulls += pr_j["size"]
            pullIssueWiki = [pulls, v["has_issues"], v["has_wiki"], v["full_name"]]
            repo_pullIssueWiki[v["full_name"]] = pullIssueWiki
        except urllib.error.HTTPError:
            continue

repo_pullIssueWiki_sorted = sorted(repo_pullIssueWiki, key=repo_pullIssueWiki.get)
for r in repo_pullIssueWiki_sorted:
    pullIssueWiki = repo_pullIssueWiki[r]
    has_issues = "[X]" if repo_pullIssueWiki[r][1] else ""
    has_wiki = "[X]" if repo_pullIssueWiki[r][2] else ""
    print("| %s | %d | %s | %s |" % \
        (r, repo_pullIssueWiki[r][0], has_issues, has_wiki))
