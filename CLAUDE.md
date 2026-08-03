# CLAUDE.md - terraform-azure-datafold

Terraform module for provisioning a Datafold dedicated-cloud deployment on Azure (AKS cluster + supporting infra).

## Per-component cloud identity: generic, caller-populated (not hardcoded per component)

`modules/aks/main.tf:171-229` creates Azure Workload Identity resources (`azurerm_user_assigned_identity.workload_identities`, `azurerm_federated_identity_credential.workload_credentials`, `azurerm_role_assignment.workload_identity_roles`) keyed off a generic `var.service_accounts` map (`variables.tf:138-149`, default `{}`). Unlike AWS's `terraform-aws-datafold` (which hardcodes a role per component — `server`, `worker`, `dfshell`, `dma`, etc. in `modules/eks/roles.tf`), this module creates **whatever identities the caller's map specifies** — no `server`/`worker`/`dfshell`/`dma` names are hardcoded anywhere in this repo. Whoever provisions a new Azure customer must populate `var.service_accounts` themselves for every component that needs a cloud identity.

The Helm side (`helm-charts`) has dedicated `serviceAccount.azureClientId`/`azureTenantId` fields per component to consume the resulting `client_id`/`tenant_id` outputs — same manual-wiring step as AWS's `roleArn` (see `cloud-infra`'s root `CLAUDE.md` → "Editing live customer clusters" for the checklist).

## LLM provider gating: not implemented

No Azure OpenAI/Cognitive-Services-equivalent to AWS's `k8s_access_bedrock` variable exists (`grep -rn "openai\|cognitiveservices\|bedrock\|llm"` returns nothing). Non-issue today: Azure dedicated clouds run the direct-Anthropic path (`dma.rawValues.dma.use_bedrock="0"`, per `cloud-infra`'s root `CLAUDE.md`), not Bedrock. Would need to be added if that changes.

## This repo is public

Never reference customer names, deployment names, or account IDs in code, comments, docs, or examples here. Use the established generic placeholder convention instead (see `examples/deployment`, which uses `acme-datafold` as the example deployment name).
