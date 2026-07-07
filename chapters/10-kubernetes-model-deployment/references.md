# Chapter 10 References

이 문서는 2026-07-07 기준으로 확인한 공식 문서와 주요 참고 자료를 기록한다.
Kubernetes, minikube, NVIDIA device plugin, cloud provider 문서는 버전과 cluster 구성에 따라 달라질 수 있으므로 실습 전 다시 확인한다.

## Kubernetes

- Kubernetes kubeadm: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- kubeadm HA topology: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
- Kubernetes Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Service: https://kubernetes.io/docs/concepts/services-networking/service/
- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Ingress Controllers: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
- Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- Liveness, Readiness, and Startup Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Assign Pods to Nodes: https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/
- Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
- Resource Management for Pods and Containers: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

## Local and Lightweight Kubernetes

- minikube start: https://minikube.sigs.k8s.io/docs/start/
- minikube NVIDIA GPU guide: https://minikube.sigs.k8s.io/docs/tutorials/nvidia/
- K3s requirements: https://docs.k3s.io/installation/requirements
- K3s GPU support: https://docs.k3s.io/advanced#nvidia-container-runtime-support

## NVIDIA

- NVIDIA Kubernetes device plugin: https://github.com/NVIDIA/k8s-device-plugin
- NVIDIA Container Toolkit install guide: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
- NVIDIA GPU Operator: https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html

## Cloud Providers

- Amazon EKS: https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
- Google Kubernetes Engine: https://cloud.google.com/kubernetes-engine/docs
- Azure Kubernetes Service: https://learn.microsoft.com/azure/aks/

## 무엇을 중점적으로 볼 것인가

| 문서 | 먼저 볼 부분 |
| --- | --- |
| Deployment | Deployment가 ReplicaSet/Pod를 관리하는 방식, rolling update와 rollback |
| Service | Pod IP가 바뀌어도 Service가 안정적인 endpoint를 제공하는 방식 |
| Ingress | Ingress object와 Ingress controller가 서로 다른 역할이라는 점 |
| Persistent Volumes | PVC가 storage 요청이고, 실제 backend는 StorageClass/provisioner가 결정한다는 점 |
| Probes | startup/readiness/liveness probe가 각각 다른 결정을 내린다는 점 |
| Taints and Tolerations | node가 Pod를 밀어내는 조건과 Pod가 이를 허용하는 조건 |
| NVIDIA device plugin | `nvidia.com/gpu` resource가 node에 노출되는 방식과 설치 전제 조건 |
| Helm | chart, release, values의 관계와 add-on 설치/업그레이드 흐름 |
