# Some random commands

rabbitmqctl ping
rabbitmqctl status
rabbitmqctl cluster_status
rabbitmqctl --node rabbit@rabbitmq-1.rabbitmq.itsystems-lab.svc.cluster.local cluster_status


rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@rabbitmq-1.rabbitmq.itsystems-lab.svc.cluster.local
rabbitmqctl start_app

rabbitmq-plugins list


http://dv1medk8labno01:31674/
guest/guest
admin
Hainoz2oquiv


k get svc -n itsystems-lab --context calab rabbitmq-itsys-001-0-nodeport -o go-template='rabbitmq-itsys-001-0: {{range .spec.ports}}{{if .nodePort}}{{.nodePort}}{{end}}{{end}}'
k get svc -n itsystems-lab --context calab rabbitmq-itsys-001-1-nodeport -o go-template='rabbitmq-itsys-001-1: {{range .spec.ports}}{{if .nodePort}}{{.nodePort}}{{end}}{{end}}'
k get svc -n itsystems-lab --context calab rabbitmq-itsys-001-2-nodeport -o go-template='rabbitmq-itsys-001-2: {{range .spec.ports}}{{if .nodePort}}{{.nodePort}}{{end}}{{end}}'



frontend  rabbitmq-itsys-001_amqp_10.13.158.134_5672 10.13.158.134:5672
    default_backend             rabbitmq-itsys-001_amqp-30129
frontend  rabbitmq-itsys-001_amqp_10.13.158.134_5673 10.13.158.134:5673
    default_backend             rabbitmq-itsys-001_amqp-30492
frontend  rabbitmq-itsys-001_amqp_10.13.158.134_5674 10.13.158.134:5674
    default_backend             rabbitmq-itsys-001_amqp-30131