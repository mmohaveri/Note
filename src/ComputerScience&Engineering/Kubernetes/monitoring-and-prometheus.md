# Monitoring & Prometheus

Notes from [Monitoring Kubernetes with Prometheus](https://www.youtube.com/watch?v=kG9p417sC3I)

Prometheus is an open source monitoring and alerting system built by SoundCloud, now part of CNCF. It has a time series
database, a simple text based metrics format (called OpenMetrics), a multidimensional data model (label bases), and a
simple query language.

Prometheus is not for logging and events, it’s really just for metrics. It’s a single binary file, responsible for
scrapping metrics from different sources. It’s highly compatible with highly dynamic environments, like kubernetes.
In kubernetes, prometheus interacts with the service discovery and track Pods as they start.

## Prometheus components

- **Targets**: are jobs and services that you want Prometheus to instrument. They expose their metrics (probably using a
   client library) for Prometheus to pull from.
  - If a job is short lived, it can push its metrics to a Pushgateway service, which fetches metrics and waits for
    prometheus to pull from it.
  - There are different exporters which allow you to gather common information from a specific service, e.g: mysql-exporter,
    cAdvisor, etc.

- **Prometheus server**: uses service discovery to find all the applications in the infrastructure, connect to them and
  scrape metrics from them.
  - Pull based metric gathering allows Prometheus to handle large workloads by adjusting itself, and reducing its pulling
    frequency.
  - It also allows Prometheus to combine service discovery information with your metrics and label them better and more automatically.

- **Alert Manager**: is responsible to send alerts to the correct set of users. Prometheus periodically runs a set of
   queries (recording and alerting rules). If an alerting rules fires, Prometheus sends a notification to the Alert Manager.
   Alert Manager’s job then is to group notifications together and route them to the correct end user.

- **PromQL**: is the API that Prometheus server exposes for data visualization and exporters tools so they’ll be able to
  query its data.

## Data Model, Series Selector, and PromQL

Prometheus stores data in a really simple data model. Each metric consists of a set of time series, and each time series
is a map from an identifier (a set of key-values, labels) to a list of timestamps (int64) and values (float64), e.g:

```
http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”200”) => [(t0, v0), (t1, v1), (t2, v3), ...]
http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”500”) => [(t’0, v’0), (t’1, v’1), ...]
http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/settings” , status=”200”) => [(t”0, v”0), (t”1, v”1), ...]
```

**Series Selectors** let the user select a subset of those time series from a metric based on its identifiers. All the
results are counters.

```
PromQL: http_request_total(job=”nignx”, status=~”5..”)
    http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”500”) => 34
    http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”502”) => 72
    http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/settings” , status=”500”) => 10
```

You can get a window over the results:

```
PromQL: http_request_total(job=”nignx”, status=~”5..”)[1m]
        http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”500”) => [30, 31, 32, 34, ...]
        http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”502”) => [4, 24, 56, 56, ...]
        http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/settings” , status=”500”) => [56, 106, 5, 96, ...]
```

Notice that because all the results are counters, they should always increase. So if all a sudden a number decreases, it
means that the job has been restarted.

Apply functions to these:

```
PromQL: rate(http_request_total(job=”nignx”, status=~”5..”)[1m])
        http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”500”) => 0.0666
        http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/home” , status=”502”) => 0.866
        http_request_total(job=”nignx”, instance=”1.2.3.4:80”, path=”/settings” , status=”500”) => 2.43
```

Aggregate by a dimension:

```
PromQL: sum by (path) (rate(http_request_total(job=”nignx”, status=~”5..”)[1m]))
        {path=”/home”} => 0.066
        {path=”/settings”} => 3.3.
```

Do binary operations:

```
PromQL: sum by (path) (rate(http_request_total(job=”nignx”, status=~”5..”)[1m])) / sum by (path) (rate(http_request_total(job=”nignx”)[1m])
        {path=”/home”} => 0.001
        {path=”/settings”} => 1.0
```

## Prometheus and Kubernetes

Kubernetes provides a very rich object model for jobs. We can take advantage of this object model to enrich our metrics.

- **[Node Exporter](https://github.com/prometheus/node_exporter)**: exports per node resource usage data.
- **[Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)**:  exports useful information about the state
  of jobs in the cluster.
- **[cAdvisor](https://github.com/google/cadvisor)**: exports per container resource consumption data.

## Monitoring and Alerting

What should you monitor?

- **USE Method**: For every resource in the cluster monitor **Utilization**, **Saturation**, and **Error rate** of that resource.
- **RED Method**: For every service in the cluster monitor **Requests rate**, **Error rate**, and **Duration** of the requests.
- **???**: Encode the expected state of the system as the invariance that you use in your alerts!

## Prometheus Operator

Prometheus is not designed to be used as a centralized instance for all metric gathering tasks of a cluster. It’s
configuration comes from a ConfigMap and using a single centralized instance for the whole cluster will cause this
ConfigMap to become uncontrollable!

As a result, it's best practice to have multiple Prometheus instances in a cluster, e.g. one instance per Node, one
instance per namespace , etc. [Prometheus Operator](https://github.com/coreos/prometheus-operator) helps us achieve this
goal with managing all these instances for us.

When installed on your cluster, Prometheus Operator creates some Custom Resource Definitions (CRD), letting us create
Prometheus instances with minimal config. Applications that want to be monitored use a Service Monitor, another CRD
defined by the operator.Service Monitors connect a set of Pods (defined by labels) to an instance of Prometheus,
created by the operator.

## Other useful resources:

- **[Kube prometheus](https://github.com/coreos/kube-prometheus)**: set of configs for running all the other things you need.
- **[Kubernetes mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin)**: set of Grafana dashboards and Prometheus
  alerts for Kubernetes.
- **[Prometheus ksonnet](https://github.com/grafana/jsonnet-libs/tree/master/prometheus-ksonnet)**: set of extensible configs
  for running Prometheus on Kubernetes.
