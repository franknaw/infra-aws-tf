### INRA Deploy TF


```
$ ./provision.sh 
6 args are required
arg 1: provision environment (dev)
arg 2: terraform function (apply|plan|show|destroy)
arg 3: component sequence (vpc|vpc_peerings|gateways|security_groups|route_tables|vpc_endpoints|route53|alb|ecr|ecs|all)
arg 4: project (INFRA)
arg 5: region (com-west|com-east)
arg 6: API Version

real	0m0.002s
user	0m0.002s
sys	0m0.000s

example:
$ ./provision.sh dev apply vpc INFRA com-east 1.0.0

When creating resource individually (not using "all"), 
both the creation and destroy component sequences matter.

Create Sequence:
(vpc|vpc_peerings|gateways|security_groups|route_tables|vpc_endpoints|route53|alb|ecr|ecs)

Destroy Sequence:
(ecs|ecr|alb|route53|vpc_endpoints|route_tables|security_groups|gateways|vpc_peerings|vpc) 

```
