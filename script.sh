#!/bin/bash

source cred.conf
command -v yq >/dev/null 2>&1 || { echo >&2 "I require yq but it's not installed. Aborting."; exit 1; }
command -v apic >/dev/null 2>&1 || { echo >&2 "I require apic but it's not installed. Aborting."; exit 1; }
mkdir tmp && touch tmp/charges.yaml && index=0

# login
apic login --username $username --password $password  \
    --server $api_mgmt \
    --realm $realm > /dev/null 2>&1

# get subscriptions
apic subscriptions:list  --catalog $catalog \
    --org $org --server $api_mgmt  \
    --scope catalog --fields "product_url, plan, state, app_url, created_at" > tmp/.subscriptions.yml

iterator=$(yq r tmp/.subscriptions.yml "total_results")


while [ $index -lt $iterator ]
do 
    # filter subscription object attributes
    product_id=$(yq r tmp/.subscriptions.yml "results[$index].product_url" | awk -F / '{print $NF}')
    plan=$(yq r tmp/.subscriptions.yml "results[$index].plan")
    status=$(yq r tmp/.subscriptions.yml "results[$index].state")
    created_at=$(yq r tmp/.subscriptions.yml "results[$index].created_at")
    app_id=$(yq r tmp/.subscriptions.yml "results[$index].app_url" | awk -F / '{print $NF}')
    consumer_org_id=$(yq r tmp/.subscriptions.yml "results[$index].app_url" | awk -F / '{print $(NF-1)}')

    # cross reference product-id against a list of products in catalog to get the product-name
    consumer_org_name=$(apic consumer-orgs:list --catalog $catalog --org $org --server $api_mgmt | grep $consumer_org_id | awk '{print $1;}')
    app_name=$(apic apps:list --catalog $catalog --org $org --server $api_mgmt --consumer-org $consumer_org_name | grep $app_id | awk '{print $1;}')
    product_name=$(apic products:list-all --catalog $catalog --org $org --server $api_mgmt --scope $scope | grep $product_id | awk '{print $1;}')

    # get product definition
    apic products:get $product_name --catalog \
        $catalog --org $org --server $api_mgmt \
        --scope catalog --output - | grep $plan -A4 > tmp/.plan.yml

    # fetch extension values
    monthly_amount=$(yq r tmp/.plan.yml "gold-plan.x-billing.monthly-amount")
    one_time_fee=$(yq r tmp/.plan.yml "gold-plan.x-billing.one-time-fee")
    currancy=$(yq r tmp/.plan.yml "gold-plan.x-billing.currancy")

    yq w -i tmp/charges.yaml "$consumer_org_name.app" $app_name
        yq w -i tmp/charges.yaml "$consumer_org_name.product-name" $product_name
        yq w -i tmp/charges.yaml "$consumer_org_name.plan" $plan
        yq w -i tmp/charges.yaml "$consumer_org_name.status" $status
        yq w -i tmp/charges.yaml "$consumer_org_name.created_at" $created_at
    
        yq w -i tmp/charges.yaml "$consumer_org_name.billing.monthly-amount" $monthly_amount
        yq w -i tmp/charges.yaml "$consumer_org_name.billing.one-time-fee" $one_time_fee
        yq w -i tmp/charges.yaml "$consumer_org_name.billing.currency" $currancy
        yq w -i tmp/charges.yaml "$consumer_org_name.billing.total-amount" $(($monthly_amount + $one_time_fee))

    index=$[$index+1]
done

# clear environment
rm tmp/.subscriptions.yml; rm tmp/.plan.yml;