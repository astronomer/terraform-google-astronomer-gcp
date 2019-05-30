#!/usr/bin/env python3
'''
VPC peering connection creation.

I didn't do this in Terraform because I felt that
it was inherently procedural, since we need to
wait on the customer to accept the request.
'''

import sys
import boto3
from time import sleep, time
from pprint import pprint
from botocore.exceptions import ClientError


def read_arguments():
    ''' Read in the arguments
    and present an informative error message if
    there are not the right number

    args:
      None

    returns:
      None
    '''
    try:
        return sys.argv[1],\
               sys.argv[2],\
               sys.argv[3],\
               sys.argv[4],\
               sys.argv[5:]
    except IndexError:
        print("Please execute like this:")
        print(
            f"python3 {sys.argv[0]} <peer_account_id> <peer_vpc_id> <peer_region> <my_vpc_id> <this_subnet_should_be_peered> <also_peer_this_subnet> <you_can_peer_as_many_as_you_like> ..."
        )
        exit(1)


def request_and_wait_for_peering_connection(client,
                                            peer_account_id,
                                            peer_vpc_id,
                                            peer_region,
                                            my_vpc_id,
                                            timeout=60*15):
    ''' Initiate a peering connection and
    wait for it to be accepted.

    args:
      client (boto3.client): A boto3 EC2 client for Astronomer's peering account
      peer_account_id (str): The account ID of our customer
      peer_vpc_id (str): The VPC ID of our customer
      peer_region (str): The region of the customer's VPC
      my_vpc_id (str): The VPC ID we want to peer with the customer

    kwargs:
      timeout (int): How many seconds to wait before giving up

    returns:
        (str, str): A tuple with the VPC peering connection ID and the CIDR of the peer's VPC
    '''
    print(
        f"Requesting peering connection with account id {peer_account_id}, vpc {peer_vpc_id}, region {peer_region}, to our vpc {my_vpc_id}\n(blocking - please wait on peer...)"
    )
    start = time()
    while time() < start + timeout:
        response = client.create_vpc_peering_connection(
            PeerOwnerId=peer_account_id,
            PeerVpcId=peer_vpc_id,
            VpcId=my_vpc_id,
            PeerRegion=peer_region)
        status = response['VpcPeeringConnection']['Status']['Code']
        print(f"Status: {status}")
        if status not in ['initiating-request',
                          'pending-acceptance',
                          'provisioning']:
            break
        sleep(10)
    if not time() < start + timeout:
        print(
            f"ERROR: Timed out waiting for peer to accept the connection. Status is {status}"
        )
        exit(1)
    if status != "active":
        print(f"ERROR: Did not find 'active' status. Status is {status}")
        exit(1)
    print("Peering connection accepted, status is 'active'.")
    peering_id = response['VpcPeeringConnection']['VpcPeeringConnectionId']
    peer_vpc_cidr = response['VpcPeeringConnection']['AccepterVpcInfo'][
        'CidrBlock']
    print(f"Peering connection id: {peering_id}")
    print(f"Peer's VPC CIDR: {peer_vpc_cidr}")
    return peering_id, peer_vpc_cidr


def get_main_route_table_of_vpc(client,
                                vpc_id):
    ''' Find the main route table for the given VPC

    args:
      client (boto3.client): A boto3 EC2 client for Astronomer's peering account
      vpc_id (str): The VPC ID of the VPC we want to find the route table for

    returns:
      (str): The ID of the main route table corresponding to the given VPC ID
    '''
    print(
        f"Finding our route table, the main route table for our VPC {vpc_id}"
    )
    response = client.describe_route_tables(Filters=[
        {
            'Name': 'vpc-id',
            'Values': [
                vpc_id,
            ]
        },
        {
            'Name': 'association.main',
            'Values': [
                'true',
            ]
        },
    ])
    route_tables = response['RouteTables']
    if len(route_tables) != 1:
        raise Exception(
            f'While looking for the main route table of vpc {vpc_id}, we expected to find exactly 1 route table, but we found {len(route_tables)}.\nRoute tables: {route_tables}'
        )

    return route_tables[0]['RouteTableId']


def add_forwarding_rules_for_vpc_peering(client,
                                         route_table_id,
                                         peer_vpc_cidr,
                                         peering_id):
    '''
    Modify a route table to forward to a peered VPC

    args:
      client (boto3.client): A boto3 EC2 client for Astronomer's peering account
      route_table_id (str): The ID of the route table to modify
      peer_vpc_cidr (str): The customer's VPC CIDR
      peering_id (str): The ID of the VPC peering connection
    returns:
      None
    '''
    print(
        f"Adding to our VPC's route table ({route_table_id}), peer's CIDR is {peer_vpc_cidr}"
    )
    try:
        _ = client.create_route(DestinationCidrBlock=peer_vpc_cidr,
                                RouteTableId=route_table_id,
                                VpcPeeringConnectionId=peering_id)
    except ClientError as e:
        # this try/except is to implement idempotency
        if not "RouteAlreadyExists" in str(e):
            raise e
    print("Modifying peering options to allow resolving DNS in the peer's VPC")


def enable_dns_resolution(client,
                          vpc_peering_connection_id):
    ''' Enable DNS resolution through the peer's VPC.
    For example, this should allow tasks running in
    our cluster to resolve private DNS in our peer's
    VPC.

    args:
      client (boto3.client): A boto3 EC2 client for Astronomer's peering account
      vpc_peering_connection_id (str): The ID of the VPC peering connection

    returns:
      None
    '''
    _ = client.modify_vpc_peering_connection_options(
        RequesterPeeringConnectionOptions={
            'AllowDnsResolutionFromRemoteVpc': True
        },
        VpcPeeringConnectionId=vpc_peering_connection_id)
    print(
        f"Enabled DNS resolution through the VPC connection {vpc_peering_connection_id}"
    )


def get_route_table_of_subnet(client,
                              subnet_id,
                              vpc_id):
    '''
    Get the route table id from a subnet id

    args:
      client (boto3.client): A boto3 EC2 client for Astronomer's peering account
      subnet_id (str): The subnet ID we want to find the route table for
      vpc_id (str): The VPC ID in which the subnet resides

    return:
      (str): The route table ID corresponding to the provided subnet
    '''
    # Maybe the VPC ID is not strictly required,
    # but I want to be extra careful because customers'
    # private cloud deployments will share an AWS account
    response = client.describe_route_tables(Filters=[
        {
            'Name': 'vpc-id',
            'Values': [
                vpc_id,
            ]
        },
        {
            'Name': 'association.subnet-id',
            'Values': [
                subnet_id,
            ]
        },
    ])
    route_tables = response['RouteTables']
    if len(route_tables) != 1:
        raise Exception(
            f'While looking for the main route table of vpc {vpc_id}, we expected to find exactly 1 route table, but we found {len(route_tables)}.\nRoute tables: {route_tables}'
        )

    return route_tables[0]['RouteTableId']

def main():
    ''' Idempotently handles VPC peering,
    blocking while waiting for the customer
    to accept the connection.
    '''
    peer_account_id,\
    peer_vpc_id,\
    peer_region,\
    my_vpc_id,\
    shared_subnets = read_arguments()

    client = boto3.client('ec2')

    # Peer with our customer's VPC
    peering_id, peer_vpc_cidr = request_and_wait_for_peering_connection(client,
                                                                        peer_account_id,
                                                                        peer_vpc_id,
                                                                        peer_region,
                                                                        my_vpc_id)

    # Allow Airflow tasks to resolve from the peer's VPC
    enable_dns_resolution(client,
                          peering_id)

    # Get a list of route table ids:
    # - main route table corresponding to our VPC
    # - route table for each specific (private) subnet we want to peer
    route_table_ids = [get_main_route_table_of_vpc(client,
                                                   my_vpc_id)]
    for subnet in shared_subnets:
        route_table_ids.append(get_route_table_of_subnet(client,
                                                         subnet,
                                                         my_vpc_id))

    # For each route table id in the list, add a rule
    # to forward traffic aimed at the peer's CIDR
    # to the VPC peering connection
    for route_table_id in route_table_ids:
        add_forwarding_rules_for_vpc_peering(client,
                                             route_table_id,
                                             peer_vpc_cidr,
                                             peering_id)


if __name__ == "__main__":
    main()
