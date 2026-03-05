# Enterprise only

## Install the enterprise license
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/configmap-grav-ee-license.yaml

## Modify APIM Rest API and Gateway deployments
### Enterprise license - add to API deployments

          #volumeMounts:
            - name: license
              mountPath: /opt/graviteeio-management-api/license/license.key
              subPath: license.key

      #volumes:
        - name: license
          configMap:
            name: grav-ee-license

### Enterprise license - add to Gateway deployments
          #volumeMounts:
            - name: license
              mountPath: /opt/graviteeio-gateway/license/license.key
              subPath: license.key

      #volumes:
        - name: license
          configMap:
            name: grav-ee-license
            

# Install gravitee ae vie helm3

## Save to a file
helm template --name-template=grav-ae graviteeio/ae --kube-context gravitee -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/ae/values.yaml > /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/ae/gravitee.yaml

### Edit deployments and add to container sections

          securityContext:
            runAsUser: 1001
            
## Enterprise license - add to Alert Engine deployment

          #volumeMounts:
            - name: license
              mountPath: /opt/graviteeio-alert-engine/license/license.key
              subPath: license.key
              
              
      #volumes:
        - name: license
          configMap:
            name: grav-ee-license
            
            
### Finally install
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/ae/gravitee.yaml


# Install gravitee Designer via helm3

##
helm template --name-template=grav-designer graviteeio/designer --kube-context gravitee -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/designer/values.yaml > /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/designer/gravitee.yaml

### Finally install
kubectl apply -f /mnt/d/git/k8s/k8s-yamls/live/lab/gravitee/designer/gravitee.yaml






        