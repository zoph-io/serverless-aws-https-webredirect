.DEFAULT_GOAL ?= help
.PHONY: help

help:
	@echo "serverless-aws-webredirect"
	@echo "${Description}"
	@echo ""
	@echo "Deploy using this order:"
	@echo "	deploy - deploy serverless-aws-webredirect stack"
	@echo "	---"
	@echo "	tear-down - destroy the CloudFormation stack"
	@echo "	clean - clean temp folders"

###################### Parameters ######################
Description ?= serverless-aws-webredirect stack
AWSRegion ?= 
SourceDomain ?= 
R53HostedZoneId ?= 
TargetURL ?= 
#######################################################

deploy:
	aws cloudformation deploy \
		--template-file ./template.yml \
		--region ${AWSRegion} \
		--stack-name "serverless-aws-webredirect" \
		--parameter-overrides \
			pSourceDomain=${SourceDomain} \
			pR53ZoneID=${R53HostedZoneId} \
			pTargetURL=${TargetURL} \
		--no-fail-on-empty-changeset

tear-down:
	@read -p "Are you sure that you want to destroy stack 'serverless-aws-webredirect'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --stack-name "serverless-aws-webredirect"
