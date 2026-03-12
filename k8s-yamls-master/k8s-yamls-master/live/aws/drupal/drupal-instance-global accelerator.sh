#GSLB:
export AWS_REGION_1=us-west-2
export AWS_REGION_2=us-east-2
export EKS_CLUSTER_1=us-west-2-lab
export EKS_CLUSTER_2=us-east-2-lab
export Ingress_1=$(kubectl get svc -n ingress-nginx ingress-nginx-controller --context us-west-2-lab \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export Ingress_2=$(kubectl get svc -n ingress-nginx ingress-nginx-controller --context us-east-2-lab \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo $Ingress_1
echo $Ingress_2


Global_Accelerator_Arn=$(aws globalaccelerator create-accelerator \
  --name multi-region-failover-miportal \
  --query "Accelerator.AcceleratorArn" \
  --output text)

Global_Accelerator_Listener_Arn=$(aws globalaccelerator create-listener \
  --accelerator-arn $Global_Accelerator_Arn \
  --region us-west-2 \
  --protocol TCP \
  --port-ranges FromPort=80,ToPort=80 FromPort=443,ToPort=443 \
  --query "Listener.ListenerArn" \
  --output text)
  
EndpointGroupArn_1=$(aws globalaccelerator create-endpoint-group \
  --region us-west-2 \
  --listener-arn $Global_Accelerator_Listener_Arn \
  --endpoint-group-region $AWS_REGION_1 \
  --query "EndpointGroup.EndpointGroupArn" \
  --health-check-interval-seconds 10 \
  --output text \
  --endpoint-configurations EndpointId=$(aws elbv2 describe-load-balancers \
    --region $AWS_REGION_1 \
    --query "LoadBalancers[?contains(DNSName, '$Ingress_1')].LoadBalancerArn" \
    --output text),Weight=128)
    
EndpointGroupArn_2=$(aws globalaccelerator create-endpoint-group \
  --region us-west-2 \
  --traffic-dial-percentage 0 \
  --listener-arn $Global_Accelerator_Listener_Arn \
  --endpoint-group-region $AWS_REGION_2 \
  --query "EndpointGroup.EndpointGroupArn" \
  --health-check-interval-seconds 10 \
  --output text \
  --endpoint-configurations EndpointId=$(aws elbv2 describe-load-balancers \
    --region $AWS_REGION_2 \
    --query "LoadBalancers[?contains(DNSName, '$Ingress_2')].LoadBalancerArn" \
    --output text),Weight=0)
    
GA_DNS=$(aws globalaccelerator describe-accelerator \
  --accelerator-arn $Global_Accelerator_Arn \
  --query "Accelerator.DnsName" \
  --output text)
  
echo copy this: $GA_DNS


DELETE GSLB:
aws globalaccelerator delete-endpoint-group --endpoint-group-arn $EndpointGroupArn_2 
aws globalaccelerator delete-endpoint-group --endpoint-group-arn $EndpointGroupArn_1
aws globalaccelerator delete-listener --listener-arn $Global_Accelerator_Listener_Arn 
aws globalaccelerator update-accelerator --accelerator-arn $Global_Accelerator_Arn --no-enabled
# You may have to wait a few seconds until the accelerator is disabled
aws globalaccelerator delete-accelerator --accelerator-arn $Global_Accelerator_Arn