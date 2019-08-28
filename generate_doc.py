#!/usr/bin/env python3
from __future__ import print_function
import argparse
import itertools
import os, subprocess
import json, xmljson
import datetime
import subprocess

from os import listdir
from xmljson import parker
try:
  from pathlib2 import Path
except:
  from pathlib import Path
from xml.etree.ElementTree import fromstring
'''
Script to generate a documentation of all libraries and keywords/functions in the repository.

Use "python3 generate_doc.py"
'''

parser = argparse.ArgumentParser(description='Generate an html document with all library and resource files'
                                +' in the repository.', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('doc', help='The file name to save the generated documentation as. ' +
                    'e.g "keywords_document.html"')
parser.add_argument('--folders','-f', nargs='*', default=['robot/resources', 'robot/libraries'],
                    help='Any number of directories containing library and resource files to be documented.' +
                    ' Seperated each directory with a space. e.g "-f robot/resources robot/libraries lib". ')

args = parser.parse_args()

def generate_doc(all_files, keywords_document_fname, dirs):
    r'''
    Generate documentation of all libraries and resources.
    '''
    print('Creating documentation file for all library and resource keywords\n {}'.format("\n".join(all_files)))
    all_contents = "["
    # Use libdoc to generate documentation for each file.
    all_files_xml = [fname.replace('.py', '_py_.xml').replace('.robot', '_robot_.xml') for fname in all_files]
    try:
        for file, f_xml in zip(all_files, all_files_xml):
            p = subprocess.check_output('python3 -m robot.libdoc {} {}'.format(file, f_xml), shell=True)
        # Get the file contents in json format.
        print('Getting json format of documented files')
        for file in all_files_xml:
            p = subprocess.check_output('xml2json -d yahoo {}'.format(file), shell=True, text=True)
            # contents_decoded = contents_converted.decode("UTF-8")
            all_contents += "\n{},".format(p)
        all_contents = all_contents[:-1] + "\n]"
        print(all_contents, file=open("lib_res_docs.json", "w"))

        # Load and store contents.
        docs = Path('lib_res_docs.json').read_text()
        docs = json.loads(docs)
        docs_formatted = []
        # Gather all doc names and file paths to create an html list by categories (function folders).
        all_doc_names = ''
        for dir, fs in dirs.items():
            dd_files = ["<a style='font-size: small;' href='#{0}'>{0}</a>".format(x) for x in [f for f in fs]]
            all_doc_names += ('\n<dt style="font-size: large; margin-left: 10px;">'+
                            '  {}</dt><dd>{}</dd>'.format(dir, " &#x00B7; ".join(dd_files)))
        # Generate a list all each library and resource file.
        # Each list item contains the library/resource file title(name),
        # documentation, and keywords with the corresponding documentation.
        for doc in docs:
            doc_details = {}
            # Add robot or py extension to resource or library documentation.
            if doc['keywordspec']['type'] == 'resource':
                doc_details['doc'] = "<p>{}robot</p>".format(doc['keywordspec']['doc'].replace('``', ''))
                doc_fname = doc['keywordspec']['name'] + '.robot'
            else:
                doc_details['doc'] = "<p>{}py</p>".format(doc['keywordspec']['doc'].replace('``', ''))
                doc_fname = doc['keywordspec']['name'] + '.py'
            doc_details['title'] = "<h2 id='{}'>{}</h2>".format(doc_fname
                                                                ,doc['keywordspec']['name'].replace('_', ' '))
            kws_list = []
            kw_names = []
            # Format keywords to be added to table.
            if 'kw' not in doc['keywordspec']:
                pass
            elif isinstance(doc['keywordspec']['kw'], list):
                for kw in doc['keywordspec']['kw']:
                    kw_name = '<td><strong> {} </strong></td>'.format(kw['name'].strip())
                    kw_names.append('<a style="font-size: small;" href="#{0}">{0}</a>'.format(kw['name']))
                    if 'arg' in kw['arguments'] and kw['arguments']['arg']:
                        if isinstance(kw['arguments']['arg'], list):
                            kw_args = '<td><var>{}</var></td>'.format(',  '.join(kw['arguments']['arg']))
                        else:
                            kw_args = '<td><var>{}</var></td>'.format(kw['arguments']['arg'])
                    else:
                        kw_args = '<td></td>'

                    kw_doc = '<td></td>'
                    if 'doc' in kw and kw['doc']:
                        kw_doc = "<td><pre>{}</pre></td>".format(kw['doc'])
                    kws_list.append('<tr id="{}"> {}\n {}\n {}</tr>'.format(kw['name'], kw_name
                                    , kw_args, kw_doc))
            else:
                kw = doc['keywordspec']['kw']
                kw_name = '<td><strong> {} </strong></td>'.format(kw['name'].strip())
                kw_names.append('<a style="font-size: small;" href="#{0}">{0}</a>'.format(kw['name']))
                td_str = '<td><var>{}</var></td>'
                if ('arg' not in kw['arguments']) or ('arg' in kw['arguments'] and kw['arguments']['arg']):
                    kw_args = '<td></td>'
                elif isinstance(kw['arguments']['arg'], list):
                    kw_args = td_str.format(',  '.join(kw['arguments']['arg']))
                else:
                    kw_args = td_str.format(kw['arguments']['arg'])

                kw_doc = '<td></td>'
                if kw['doc']:
                    kw_doc = '<td><p style="white-space: pre;"> {} </p></td>'.format(kw['doc'])
                kws_list.append('<tr id="{0}">\n\t\t {1}\n {2}\n {3}\n</tr>'.format(kw['name'], kw_name
                                , kw_args, kw_doc))
            # Add all keywords to doc_details.
            doc_details['all_kw_names'] = kw_names
            doc_details['keywords'] = kws_list
            docs_formatted.append(doc_details)
        # Create keywords html document.
        git_root = subprocess.check_output("git rev-parse --show-toplevel",shell=True).strip()
        repo_title = git_root.decode('utf-8').split('/')[-1].replace('-',' ').title() + " Keywords"
        html_doc_def = ("\n<!DOCTYPE html>\n<html>"+
                        "<title>{0}</title> <h1>{0}</h1>".format(repo_title)+
                        """<style>
                            table {
                              border-collapse: collapse;
                            }

                            table, td, th {
                              border: 1px solid black;
                            }
                            p{
                              white-space: pre-wrap;
                              font-family: "Times New Roman", Times, serif;
                            }
                            a:link {
                              text-decoration: none;
                            }
                            </style>\n<body>""")
        def_list_str = "<br><h3>Keywords and Functions Categories</h3>\n"
        time_collected_p = ('\n\t <p style="font-size: large;"> <strong>Keywords collected on:</strong> ' +
                            datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S") + '</p>\n<br><br><hr>')
        print('Writing content to html file')
        with open(keywords_document_fname, 'w') as f:
            f.write(html_doc_def + def_list_str + "<dl>" + all_doc_names + "</dl>" + time_collected_p)
            for i in docs_formatted:
                # Get a list of all the keywords for each utility (resource/library) file.
                keywords = ' \n\t\t '.join((keyword) for keyword in i['keywords'])
                # List all keywords for utility file.
                f.write('\n\t{}\n\t\t{}\n\t\t\n\t\t<div><h3>All Keywords</h3>\n\t\t<var>{}</var></div><br><br>\
                        '.format(i['title'], i['doc'], ',  '.join(i['all_kw_names'])))
                # Add the arguments.
                start_tbody = "\n\t<table cellpadding='5'>\n\t<tbody>"
                close_tbody = "</tbody>\n\t</table>\n<br><br><hr>"
                t_headers = "<tr><th class='kws'>Keyword</th><th class='args'>Arguments</th>"\
                            + "<th class='docs'>Documentation</th></tr>"
                f.write("{}\n\t{}\n{}\n{}".format(start_tbody, t_headers, keywords, close_tbody))
            # Close html body and html.
            f.write("</body>\n</html>")
        print('Created library and resource documentation file: {}'.format(keywords_document_fname))
        # Clean up files
        print('Cleaning up xml files created for documentation')
        subprocess.run('rm {}'.format(' '.join(all_files_xml)), shell=True, check=True)
    except Exception as e:
        try:
            subprocess.run('rm {}'.format(' '.join(all_files_xml)), shell=True, check=True)
        except:
            pass
        raise Exception(e)

if __name__ == "__main__":
    dirs_not_found = [d for d in args.folders if not Path(d).exists()]
    if dirs_not_found:
        raise FileNotFoundError("The following directories were not found:\n" + "\n".join(dirs_not_found))
    dirs_and_files = {}
    all_files = []
    for dir, subdirs, files in itertools.chain.from_iterable(os.walk(path) for path in args.folders):
        rnpy_files = [f for f in files if f.endswith('.py') or f.endswith('.robot')]
        if (rnpy_files):
            dirs_and_files[dir] = rnpy_files
            all_files = all_files + [dir+'/'+f for f in rnpy_files]
    generate_doc(sorted(all_files), args.doc, dirs_and_files)
