- substitute the word "ROUTER" with appropriate name/labels
- substitute image with correct image
- substitute correct port numbers
- add readiness/liveness probes
- add resources
- add securityContext
- prestop sleep optional - allows k8s to remove service discovery endpoints prior to actual shutdown in order to give more quiesce time
- for worker to connect to specific router pod instance (this made possible by statefulset combined with headless service) connect to <podname>.<servicename>
  example: router-0.router-headless
           router-1.router-headless
           router-2.router-headless
- FQDN form is <podname>.<servicename>.<namespace>.svc.cluster.local
  example: router-0.router-headless.ppas-dev.svc.cluster.local
- You cannot connect to the naked "router-headless" name as you would a normal service. That's why the non-headless service also is created. Thart's a normal load balanced service that you can connect to, appropriate for the adapter to use.