pxc:
  image: registry.vxcontrol.com:8443/percona-xtradb-cluster:5.7.17-29.20-alpine
  environment:
    MYSQL_ROOT_PASSWORD: "${mysql_root_password}"
    PXC_SST_PASSWORD: "${pxc_sst_password}"
    MYSQL_DATABASE: "${mysql_database}"
    MYSQL_USER: "${mysql_user}"
    MYSQL_PASSWORD: "${mysql_password}"
    CLUSTER_NAME: "${cluster_name}"
    DISCOVERY_SERVICE: etcd
  labels:
    io.rancher.sidekicks: pxc-data,pxc-clustercheck
    io.rancher.container.hostname_override: container_name
    io.rancher.scheduler.affinity:host_label_soft: pxc=true
    io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    {{- if .Values.SC_LABEL_VALUE }}
    io.rancher.scheduler.affinity:host_label: ${SC_LABEL_VALUE}
    {{- end }}
  volumes_from:
    - 'pxc-data'
  volume_driver: ${storage_driver}
  external_links:
    - ${etcd_service}:etcd
    - pxc-lb:loadbalancer
  entrypoint: /opt/rancher/start_etcd
pxc-data:
  image: registry.vxcontrol.com:8443/percona-xtradb-cluster:5.7.17-29.20-alpine
  net: none
  environment:
    MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
  volumes:
    - ${volume_data}/var/lib/mysql
    - /etc/mysql/conf.d
    - /etc/mysql/percona-xtradb-cluster.conf.d
    - /docker-entrypoint-initdb.d
  volume_driver: ${storage_driver}
  command: /bin/true
  labels:
    io.rancher.container.start_once: true
    {{- if .Values.SC_LABEL_VALUE }}
    io.rancher.scheduler.affinity:host_label: ${SC_LABEL_VALUE}
    {{- end }}
pxc-clustercheck:
  image: registry.vxcontrol.com:8443/percona-xtradb-cluster-clustercheck:1.0.0
  net: "container:pxc"
  labels:
    io.rancher.container.hostname_override: container_name
    {{- if .Values.SC_LABEL_VALUE }}
    io.rancher.scheduler.affinity:host_label: ${SC_LABEL_VALUE}
    {{- end }}
  volumes_from:
    - 'pxc-data'
  volume_driver: ${storage_driver}
pxc-lb:
  expose:
  - 3306:3306/tcp
  tty: true
  image: rancher/load-balancer-service
  links:
  - pxc:pxc
  stdin_open: true
  labels:
    {{- if .Values.SC_LABEL_VALUE }}
    io.rancher.scheduler.affinity:host_label: ${SC_LABEL_VALUE}
    {{- end }}