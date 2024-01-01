.DEFAULT_GOAL := help
.PHONY: help

help:
	@echo "serverless-aws-webredirect"
	@echo "${Description}"
	@echo "Provided by zoph.io folks"
	@echo ""
	@echo "Deploy using this order:"
	@echo "	requirements - deploy prerequisites S3 bucket"
	@echo "	deploy - deploy serverless-aws-webredirect stack"
	@echo "	check - check parameters"
	@echo "	---"
	@echo "	tear-down - destroy the CloudFormation stack"
	@echo "	clean - clean temp folders"

###################### Parameters ######################
ProjectName := change_me
ProductName := serverless-aws-webredirect
Description := "zoph.io - Serverless AWS WebRedirect"
AWSRegion := eu-west-1

# Source domain and subdomains
SourceNakedDomain := domain.tld
SourceSubDomainList := "sub1,sub2,blog"

# Route53 Hosted Zone ID for NakedDomain
R53HostedZoneId := "Z1BPJ53MJJXXX"
# ACM Certificate ARN for NakedDomain
CertificateArn := "arn:aws:acm:us-east-1:123456789012:certificate/32d12307-3fd1-4685-9e29-096820fc9d85"
#######################################################

###################### Do not change me ######################
# Extracting the first item from SourceSubDomainList
FirstSourceSubDomain := $(shell echo $(SourceSubDomainList) | cut -d ',' -f1)
# Deriving SourceDomain from NakedDomain and ProjectName
SourceDomain := $(FirstSourceSubDomain).$(SourceNakedDomain)
# Deriving SourceSubDomainListUrl from SourceSubDomainList and NakedDomain
SourceSubDomainListUrl := $(shell echo $(SourceSubDomainList) | sed 's/,/.$(SourceNakedDomain),/g').$(SourceNakedDomain)
##############################################################


requirements:
	@if ! aws s3 ls "s3://${ProductName}-${ProjectName}-config" --region ${AWSRegion} >/dev/null 2>&1; then \
		echo "🚀 Creating bucket ${ProductName}-${ProjectName}-config in region ${AWSRegion}..."; \
		aws s3 mb "s3://${ProductName}-${ProjectName}-config" --region ${AWSRegion}; \
		aws s3 cp ./config.json s3://${ProductName}-${ProjectName}-config/ --region ${AWSRegion}; \
	else \
		echo "✅ Bucket ${ProductName}-${ProjectName}-config already exists in region ${AWSRegion}. Skipping creation."; \
	fi

copy-config:
	aws s3 cp ./config.json s3://${ProductName}-${ProjectName}-config/ --region ${AWSRegion}


deploy:
	aws cloudformation deploy \
		--template-file ./template.yml \
		--region ${AWSRegion} \
		--stack-name "serverless-aws-webredirect-${ProjectName}" \
		--parameter-overrides \
			pProjectName=${ProjectName} \
			pProductName=${ProductName} \
			pDescription=${Description} \
			pR53ZoneId=${R53HostedZoneId} \
			pSourceNakedDomain=${SourceNakedDomain} \
			pSourceDomain=${SourceDomain} \
			pSourceSubDomainList=${SourceSubDomainList} \
			pSourceSubDomainListUrl=${SourceSubDomainListUrl} \
			pCertificateArn=${CertificateArn} \
		--no-fail-on-empty-changeset

test:
	@echo "Curling \033[0;34m${SourceDomain}\033[0m..."
	@RESPONSE_CODE=$$(curl -o /dev/null -s -w "%{http_code}" https://${SourceDomain}); \
	if [ "$$RESPONSE_CODE" = "301" ]; then \
		echo "\033[0;32mSuccess - HTTP301 🎉\033[0m"; \
		echo "\033[0;34m$$(curl -s -I https://${SourceDomain});\033[0m"; \
	else \
		echo "\033[0;31mFailed with code $$RESPONSE_CODE\033[0m"; \
		echo "\033[0;34m$$(curl -s -I https://${SourceDomain});\033[0m"; \
	fi

check:
	@echo "ProjectName: ${ProjectName}"
	@echo "ProductName: ${ProductName}"
	@echo "Description: ${Description}"
	@echo "AWSRegion: ${AWSRegion}"
	@echo "SourceNakedDomain: ${SourceNakedDomain}"
	@echo "SourceDomain: ${SourceDomain}"
	@echo "SourceSubDomainList: ${SourceSubDomainList}"
	@echo "SourceSubDomainListUrl: ${SourceSubDomainListUrl}"
	@echo "R53HostedZoneId: ${R53HostedZoneId}"
	@echo "CertificateArn: ${CertificateArn}"

tear-down:
	@read -p "Are you sure that you want to destroy stack 'serverless-aws-webredirect-${ProjectName}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --stack-name "serverless-aws-webredirect-${ProjectName}"
