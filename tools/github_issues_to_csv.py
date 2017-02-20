#!/usr/bin/env python

r"""
Exports issues from a list of repositories to individual csv files.
Uses basic authentication (Github username + password) to retrieve issues
from a repository that username has access to. Supports Github API v3.
"""
import argparse
import csv
from getpass import getpass
import requests

auth = None
states = 'all'


def write_issues(response, csv_out):
    r"""
    Parses JSON response and writes to CSV.
    """
    print response
    if response.status_code != 200:
        raise Exception(response.status_code)
    for issue in response.json():
        if 'pull_request' not in issue:
            labels = ', '.join([l['name'] for l in issue['labels']])
            date = issue['created_at'].split('T')[0]
            # Change the following line to write out additional fields
            csv_out.writerow([labels.encode('utf-8'),
                             issue['title'].encode('utf-8'),
                             issue['state'].encode('utf-8'),
                             date.encode('utf-8'),
                             issue['html_url'].encode('utf-8'),
                             issue['user']['login'].encode('utf-8')])


def get_issues_from_github_to_csv(name):
    r"""
    Requests issues from GitHub API and writes to CSV file.
    """
    print name
    print states
    l_url = 'https://api.github.com/repos/{}/issues?state={}'.format(name,
                                                                     states)
    print l_url
    # 'https://api.github.com/repos/{}/issues?state={}'.format(name, state)
    response = requests.get(l_url, auth=auth)

    csvfilename = '{}-issues.csv'.format(name.replace('/', '-'))
    with open(csvfilename, 'w') as csvfile:
        csv_out = csv.writer(csvfile)
        csv_out.writerow(['Labels', 'Title', 'State', 'Date', 'URL', 'Author'])
        write_issues(response, csv_out)

        # Multiple requests are required if response is paged
        if 'link' in response.headers:
            pages = {rel[6:-1]: url[url.index('<')+1:-1] for url, rel in
                     (link.split(';') for link in
                      response.headers['link'].split(','))}
            while 'last' in pages and 'next' in pages:
                pages = {rel[6:-1]: url[url.index('<')+1:-1] for url, rel in
                         (link.split(';') for link in
                          response.headers['link'].split(','))}
                response = requests.get(pages['next'], auth=auth)
                write_issues(response, csv_out)
                if pages['next'] == pages['last']:
                    break

        csvfile.close()

parser = argparse.ArgumentParser(description="Write GitHub repository issues "
                                             "to CSV file.")

parser.add_argument('username', nargs='+', help="Github user name, "
                    "formatted as 'username'")

parser.add_argument('password', nargs='+', help="Github username password, "
                    "formatted as 'password'")

parser.add_argument('repositories', nargs='+', help="Repository names, "
                    "formatted as 'basereponame/repo'")

parser.add_argument('--all', action='store_true', help="Returns both open "
                    "and closed issues.")
args = parser.parse_args()

if args.all:
    state = 'all'

for argusername in args.username:
    username = argusername

for argpassword in args.password:
    password = argpassword

auth = (username, password)

for repository in args.repositories:
    get_issues_from_github_to_csv(repository)
