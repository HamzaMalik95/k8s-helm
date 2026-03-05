# Prep before install

## Add the helm repo
helm repo add graviteeio https://helm.gravitee.io
helm repo update

## Set active context to gravitee namespace
kubectl config set-context gravitee --namespace=gravitee-lab --cluster=calab --user=mdeckert && kubectl config use-context gravitee


# Generate yaml for gravitee apim 3.x via helm3

## Save to a file
helm template --name-template=gio graviteeio/apim3 --kube-context gravitee -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/values.yaml > /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/gravitee.yaml

## Add section to grav3-apim3-api configmap

data:
  gravitee.yml: |

    jetty:
      accesslog:
        enabled: false
        path: ${gravitee.home}/logs/gravitee_accesslog_yyyy_mm_dd.log

## Set periodSeconds to 10 in readinessProbe in grav3-apim3-api deployment

          readinessProbe:
            tcpSocket:
              port: 8083
            initialDelaySeconds: 60
            periodSeconds: 10
            
## Set initialDelaySeconds to 30 and periodSeconds to 10 in readinessProbe in grav3-apim3-gateway deployment

          readinessProbe:
            tcpSocket:
              port: 8082
            initialDelaySeconds: 40
            periodSeconds: 10
            
## OPTIONAL (currently no effect): Add startupProbe section in grav3-apim3-gateway deployment

          startupProbe:
            exec:
              command:
              - /bin/sh
              - -c
              - wget -S -q -O - admin:adminadmin@127.0.0.1:18082/_node/health 2>&1|grep -q 'HTTP/1.1 200 OK'
            initialDelaySeconds: 40
            periodSeconds: 10
            
## SPLUNK

      
      
      # Splunk reporter
      splunk:
        enabled: true # Is the reporter enabled or not (default to true)
        # 'hec' is HTTP Event Collector
        hec_endpoint: https://splunk.medimpact.com:8088/services/collector/event
        # in milliseconds:
        connect_timeout: 1000
        request_timeout: 2000
        # The type of info to report, along with the authorization token.
        # If it's not here it won't be reported.
        message_types:
          - type: endpoint_status
            auth: ce2e4991-9b6c-470b-9da3-200644297890
          - type: log
            auth: 9fc936fa-90f5-41cd-9598-7c9c12589325
          - type: metrics
            auth: 472585ff-5493-49ff-b451-d849c489a9df
          - type: monitor
            auth: 706bd063-c4d2-4341-9cc4-725abf36d593
      
      
      
      
      
            
            

# Deploy redis if not already
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/1-deploy-redis.yaml

# Add cert (if not already)
#kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/2-secret-medimpact-certs.yaml  

# Add additional services within the namespace for internal component use
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/svc-api-lab.yaml
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/svc-api-dev.yaml
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/svc-api-qa.yaml

# Add ingresses for gateway itself
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/5-ing-gateway.yaml

# Install APIM
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/apim/gravitee.yaml















