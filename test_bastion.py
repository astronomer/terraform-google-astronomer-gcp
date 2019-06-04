#!/usr/bin/env python
'''
This file is the generic test to be run targeting the bastion.
It should ensure that that astronomer infrastructure layer is
correctly set up
'''

import testinfra
import re

def test_for_required_files(host):
    ''' Test that the files which are always required are present
    '''
    required_files = [
        '/opt/tls_secrets/tls.crt',
        '/opt/tls_secrets/tls.key',
        '/opt/db_password/connection_string'
    ]
    for path in required_files:
        assert host.file(path).exists, \
            f"Expected {path} to exist."

def test_kubeadmin(host):
    ''' Test that the user host is a kube admin
    '''
    command = "KUBECONFIG=/opt/astronomer/kubeconfig /snap/bin/kubectl auth can-i '*' '*' --all-namespaces"
    host.check_output(command) == 'yes'

def test_db_connection(host):
    ''' Test that the db connection string is present
    and works to connect to the database
    '''
    path = '/opt/db_password/connection_string'
    user = 'airflow'
    db_connection_string = \
        host.file(path).content_string
    connection_string_regex = \
        re.compile("^postgres:\/\/(" + user + "):([^@]*)@([^:]*):(\d{1,5})$")
    matches = connection_string_regex.findall(db_connection_string)
    assert len(matches) > 0, \
        f"Expected db_connection_string located at {path} to match the pattern {connection_string_regex.pattern}"
    user, password, endpoint, port =  matches[0]
    db_check_command = \
        f'psql -d "postgresql://{user}:{password}@{endpoint}:{port}/not_a_real_database" -c "\l"'
    expected_response = 'psql: FATAL:  database "not_a_real_database" does not exist'
    response = host.run(db_check_command)
    assert expected_response in response.stderr


