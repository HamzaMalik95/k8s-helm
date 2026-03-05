## Naming convention
*Persistent Volume*: pv-\<storage type>-\<namespace>-\<volume name>.yaml

*Persistent Volume Claim*: pvc-\<namespace>-\<volume name>.yaml


## Example Deployment
Two k8s objects need to exist for a volume to be available to a Deployment within one namespace.  To mount the same PVC into a deployment in a different namespace, a separate PV and PVC must be created.

* The *Persistent Volume* exists at the cluster scope and has the actual NFS export path and NFS-specific mount options.
* The *Persistent Volume Claim* exists in the namespace and references (claims) the PV.
* Finally, the yaml below shows usage of the volumes and volumeMounts specs in a Deployment to mount a PVC into a container

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: marktest
  name: marktest
  namespace: itsystems-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: marktest
  template:
    metadata:
      labels:
        app: marktest
    spec:
      containers:
      - image: drydock.medimpact.com/simple-hello-www:1
        name: simple-hello-www
        volumeMounts:
          # name must match the volume name below
          - name: my-nfs-mount
            mountPath: "/mnt"
      securityContext:
        runAsUser: 5555
      volumes:
      # claimName must match the PVC name
      - name: my-nfs-mount
        persistentVolumeClaim:
          claimName: example-dev
```


## Example PV and PVCs

- We have an nfs export on 10.13.155.246:/pv1medvfiler3_vol_example_dev/qtree_example_dev
- This nfs share needs to be available in the itsystems-dev team namespace

These would be the resulting PV and PVCs

### PV example (Filename: pv-nfs-itsystems-dev-example-dev.yaml)
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-itsystems-dev.example-dev
  labels: 
    volname: itsystems-dev.example-dev
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  mountOptions:
    - rsize=8192
    - wsize=8192
    - timeo=14
    - intr
    - vers=3
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  nfs:
    server: 10.13.155.246
    path: "/pv1medvfiler3_vol_example_dev/qtree_example_dev"
```

### PVC example (Filename pvc-itsystems-dev-example-dev.yaml):
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-dev
  namespace: itsystems-dev
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: nfs
  selector:
    matchLabels:
      volname: itsystems-dev.example-dev
```