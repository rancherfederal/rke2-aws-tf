<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent"></a> [agent](#input\_agent) | Toggle server or agent init, defaults to agent | `bool` | `true` | no |
| <a name="input_ccm"></a> [ccm](#input\_ccm) | Toggle cloud controller manager | `bool` | `false` | no |
| <a name="input_ccm_external"></a> [ccm\_external](#input\_ccm\_external) | Set kubelet arg 'cloud-provider-name' value to 'external'.  Requires manual install of CCM. | `bool` | `false` | no |
| <a name="input_config"></a> [config](#input\_config) | RKE2 config file yaml contents | `string` | `""` | no |
| <a name="input_post_userdata"></a> [post\_userdata](#input\_post\_userdata) | Custom userdata to run immediately after rke2 node attempts to join cluster | `string` | `""` | no |
| <a name="input_pre_userdata"></a> [pre\_userdata](#input\_pre\_userdata) | Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed | `string` | `""` | no |
| <a name="input_rke2_start"></a> [rke2\_start](#input\_rke2\_start) | Start/Stop value for the rke2-server/agent service.  This will prevent the service from starting until the next reboot. True=start, False= don't start. | `bool` | `true` | no |
| <a name="input_server_url"></a> [server\_url](#input\_server\_url) | rke2 server url | `string` | n/a | yes |
| <a name="input_token_bucket"></a> [token\_bucket](#input\_token\_bucket) | Bucket name where token is located | `string` | n/a | yes |
| <a name="input_token_object"></a> [token\_object](#input\_token\_object) | Object name of token in bucket | `string` | `"token"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_post_templated"></a> [post\_templated](#output\_post\_templated) | n/a |
| <a name="output_pre_templated"></a> [pre\_templated](#output\_pre\_templated) | n/a |
| <a name="output_rke2_templated"></a> [rke2\_templated](#output\_rke2\_templated) | n/a |
<!-- END_TF_DOCS -->