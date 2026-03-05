# Generate vm.yaml
helm template victoria-metrics vm/victoria-metrics-cluster -n victoriametrics > git/k8s/k8s-yamls/live/cadev/victoriametrics/vmnew.yaml