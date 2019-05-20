import os
import boto3

client = boto3.client('elb')
vpc_id = os.environ['VPC_ID']
cluster_name = os.environ['CLUSTER_NAME']

def _get_elb_name():
    response = client.describe_load_balancers()
    load_balancers = response['LoadBalancerDescriptions']

    # get all the ELBs in this VPC
    load_balancer_names_in_vpc = []
    for lb in load_balancers:
        if lb['VPCId'] == vpc_id:
            load_balancer_names_in_vpc.append(lb["LoadBalancerName"])

    # get the tags
    response = client.describe_tags(
        LoadBalancerNames=load_balancer_names_in_vpc)

    # return the name of the ELB corresponding to this cluster
    for description in response['TagDescriptions']:
        for tag in description['Tags']:
            if tag['Key'] == f"kubernetes.io/cluster/{cluster_name}":
                return {
                    "Name" : description['LoadBalancerName']
                }

    return None

def my_handler(event, context):
    return _get_elb_name()
