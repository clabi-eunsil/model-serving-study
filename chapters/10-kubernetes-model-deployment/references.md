# References

Kubernetes, minikube, NVIDIA device plugin, cloud provider 문서는 버전과 cluster 구성에 따라 달라질 수 있다.  
실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| Kubernetes Deployment | https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ | Deployment가 ReplicaSet과 Pod를 관리하는 방식, rolling update, rollback 개념을 본다. |
| Kubernetes Service | https://kubernetes.io/docs/concepts/services-networking/service/ | Pod IP가 바뀌어도 Service가 안정적인 endpoint를 제공하는 방식을 본다. |
| Kubernetes Ingress | https://kubernetes.io/docs/concepts/services-networking/ingress/ | Ingress object가 HTTP routing rule이고, 실제 traffic 처리는 controller가 담당한다는 점을 확인한다. |
| Ingress Controllers | https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/ | nginx, cloud provider controller처럼 Ingress를 실제 proxy/load balancer 설정으로 반영하는 구성요소를 본다. |
| Persistent Volumes | https://kubernetes.io/docs/concepts/storage/persistent-volumes/ | PVC가 storage 요청이고, 실제 backend는 StorageClass/provisioner가 결정한다는 점을 본다. |
| Liveness, Readiness, Startup Probes | https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ | startup/readiness/liveness probe가 각각 어떤 결정을 내리는지와 모델 로딩이 긴 서버에서의 주의점을 본다. |
| Assign Pods to Nodes | https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/ | `nodeSelector`, node label, node affinity로 Pod 배치 조건을 지정하는 방식을 본다. |
| Taints and Tolerations | https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ | node가 Pod를 밀어내는 조건과 Pod가 이를 허용하는 조건을 구분한다. |
| Resource Management for Pods and Containers | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ | CPU/memory request와 limit이 scheduling과 OOM/throttling에 어떤 영향을 주는지 확인한다. |
| kubeadm | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ | 직접 Kubernetes cluster를 구성할 때 필요한 control plane, worker join, bootstrap 흐름을 본다. |
| kubeadm HA topology | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/ | control plane HA를 직접 구성할 때 etcd quorum, load balancer, 운영 책임이 커지는 지점을 본다. |
| minikube start | https://minikube.sigs.k8s.io/docs/start/ | local 단일 node Kubernetes cluster를 만드는 방법과 driver 선택을 본다. |
| minikube NVIDIA GPU guide | https://minikube.sigs.k8s.io/docs/tutorials/nvidia/ | GPU host에서 minikube GPU passthrough를 구성할 때 필요한 조건을 확인한다. |
| K3s requirements | https://docs.k3s.io/installation/requirements | 가벼운 Kubernetes 배포판의 최소/권장 리소스와 설치 전제 조건을 본다. |
| K3s NVIDIA runtime support | https://docs.k3s.io/advanced#nvidia-container-runtime-support | k3s에서 NVIDIA container runtime을 사용할 때 필요한 설정을 확인한다. |
| NVIDIA Kubernetes device plugin | https://github.com/NVIDIA/k8s-device-plugin | GPU를 `nvidia.com/gpu` resource로 노출하는 DaemonSet, Helm 설치 방식, 설정 옵션을 본다. |
| NVIDIA Container Toolkit install guide | https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html | container가 host NVIDIA GPU를 사용할 수 있게 하는 toolkit 설치와 runtime 설정을 본다. |
| NVIDIA GPU Operator | https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html | driver, toolkit, device plugin, DCGM 등을 operator로 관리하는 방식과 중복 설치 주의점을 본다. |
| Amazon EKS | https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html | managed Kubernetes에서 control plane과 node group이 어떻게 관리되는지 본다. |
| Google Kubernetes Engine | https://cloud.google.com/kubernetes-engine/docs | GKE에서 cluster, node pool, GPU node, storage, ingress를 관리하는 방식을 본다. |
| Azure Kubernetes Service | https://learn.microsoft.com/azure/aks/ | AKS에서 managed Kubernetes를 사용할 때 node pool, GPU, ingress, storage 구성을 확인한다. |

## 업데이트 가능성이 큰 정보

- Kubernetes version에 따라 `kubectl` 출력, Endpoint/EndpointSlice 권장 방식, API field가 달라질 수 있다.
- minikube driver와 GPU passthrough 지원은 host OS, Docker Desktop, NVIDIA driver 상태에 영향을 받는다.
- NVIDIA device plugin version, Helm chart value, GPU Operator 권장 방식은 바뀔 수 있다.
- managed Kubernetes는 cloud provider별 GPU node image, driver 설치 방식, StorageClass 이름, Ingress/LB 구성이 다르다.
- K3s/kubeadm 환경은 CNI, container runtime, storage provisioner를 사용자가 직접 선택해야 한다.
- 모델 서버 probe 값은 모델 크기와 loading time에 따라 조정해야 한다.
