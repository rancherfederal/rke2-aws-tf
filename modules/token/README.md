# Token Retrieval

`rke2` uses tokens in addition to certificates for joining additional servers and/or agents to the cluster.

Due to the auto-join nature of this iac, nodes joining the cluster must be able to self retrieve the join token.

A common approach is to store the token within the userdata, but this can be insecure since the any user with read access to the ec2 instances in the aws console has the ability to read instances userdata as plaintext.

Since this iac is specific to AWS, several options are provided for a central secret store for storing and retrieving the token in a secure fashion.  These are provided as terraform modules within this repo that have the following requirements:

__inputs__:

* `name`: name of the cluster
* `token`: plaintext value of the token

__outputs__:

* `token`: an object containing the following
  * `address`: the identifier of the secret corresponding to it's retrieval in the bootstrap userdata
  * `policy_document`: the bare minimum policy document attached to the node role required to retrieve the secret
  
Currently this module supports two state storages:

* `secretsmanager`: default and recommended option
* `s3`: solely for supporting legacy environments without access to secretsmanager (such as C2S)