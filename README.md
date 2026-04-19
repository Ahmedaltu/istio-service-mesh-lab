# istio-service-mesh-lab

A hands-on Istio service mesh deployment on Kubernetes (Kind), demonstrating traffic management, automatic mTLS, and sidecar injection using the Bookinfo sample application.



---

## What is Istio?

Istio is a service mesh that manages all network communication between microservices in a Kubernetes cluster. It works by injecting an **Envoy proxy sidecar** into every pod, which intercepts all inbound and outbound traffic. This gives you:

- **Automatic mTLS** — all service-to-service traffic is encrypted without code changes
- **Traffic management** — canary deployments, A/B testing, circuit breakers, retries
- **Observability** — automatic metrics, traces, and logs for every request
- **Policy enforcement** — control which services can communicate with which

### Why Istio used

In a 5G network, hundreds of microservices (network functions like AMF, SMF, UPF) communicate with each other. Istio lets enforce security policies and observe traffic between these functions without modifying each service individually — critical at telecom scale.

---

## Stack

| Component | Role |
|---|---|
| **Kind** | Kubernetes IN Docker — local cluster |
| **Istio 1.29.2** | Service mesh control plane (istiod) |
| **Envoy** | Sidecar proxy injected into every pod |
| **Bookinfo** | Sample microservices app (4 services, 3 versions) |
| **istioctl** | Istio CLI for install, analysis, and debugging |

---

## Prerequisites

- Docker
- Kind
- kubectl
- GCP VM or local Linux machine (4 vCPU, 8GB RAM minimum)

---

## Quickstart

### 1. Create Kind cluster

```bash
kind create cluster --name istio-lab
kubectl get nodes
```

### 2. Install Istio

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.29.2
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
kubectl get pods -n istio-system
```

### 3. Enable sidecar injection

```bash
kubectl label namespace default istio-injection=enabled
```

### 4. Deploy Bookinfo

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl get pods
```

Notice each pod shows `2/2` READY — the second container is the Envoy sidecar automatically injected by Istio.

### 5. Verify the mesh

```bash
# Confirm the app is running through the mesh
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" \
  -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

# Check proxy status across the mesh
istioctl proxy-status

# Analyze mesh configuration
istioctl analyze
```

### 6. Apply destination rules

```bash
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

---

## Traffic Management

### Route all traffic to v1 (no star ratings)

```bash
kubectl apply -f traffic-management/virtual-service-all-v1.yaml
```

### Switch all reviews traffic to v3 (red stars)

```bash
kubectl apply -f traffic-management/virtual-service-reviews-v3.yaml
```

This demonstrates zero-downtime traffic switching — changing which version of a service receives traffic by applying a YAML file, without touching the actual services. In Ericsson's 5G infrastructure this enables rolling out new network function versions to a subset of traffic before full deployment.

---

## Screenshots

### Pods running with Envoy sidecars (2/2)
![Pods](screenshots/01_pods_running.png)

### Bookinfo response through the mesh
![Bookinfo](screenshots/02_bookinfo_response.png)

### Traffic routing via VirtualService
![Traffic](screenshots/03_traffic_routing.png)

---

## Key concepts

**Sidecar injection** — Istio automatically injects an Envoy proxy container into every pod in labeled namespaces. The `2/2` in pod READY status confirms injection: one container is your app, the other is the proxy.

**VirtualService** — defines traffic routing rules. You can route based on headers, weights, source labels, or any combination. This is how canary deployments work in Istio.

**DestinationRule** — defines policies that apply to traffic after routing. Subsets group pods by version labels, enabling version-specific traffic policies.

**istioctl analyze** — built-in diagnostic tool that validates your mesh configuration against known issues. Run it after any configuration change.

---

## Open Source Contribution

While working with this setup, I identified a documentation gap in the official Istio docs — the Bookinfo getting started guide does not mention that applying `destination-rule-all.yaml` produces expected `IST0173` analyzer warnings for the `v2-mysql` and `v2-mysql-vm` subsets, which are not deployed in a standard installation. I submitted a fix:

**PR #17329 on istio/istio.io:** [docs: add note about expected IST0173 warnings when applying Bookinfo destination rules](https://github.com/istio/istio.io/pull/17329)

---

## Teardown

```bash
kind delete cluster --name istio-lab
```

---

## References

- [Istio official docs](https://istio.io)
- [Bookinfo sample application](https://istio.io/latest/docs/examples/bookinfo/)
- [Ericsson's Istio contributions](https://istio.io/latest/blog/2026/steering-election-results/)
- [CNCF Istio project page](https://www.cncf.io/projects/istio/)

---

*Deployed on GCP (n2-standard-4, Kind) — April 2026 | Aalto University*
