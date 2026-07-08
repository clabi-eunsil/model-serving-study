# Chapter 10 Lab Notes

## Sources

- Kubernetes Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes Service: https://kubernetes.io/docs/concepts/services-networking/service/
- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Persistent Volumes and PVC: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- Liveness, Readiness, Startup Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
- minikube start: https://minikube.sigs.k8s.io/docs/start/
- NVIDIA Kubernetes device plugin: https://github.com/NVIDIA/k8s-device-plugin
- Helm using Helm: https://helm.sh/docs/intro/using_helm/

## Environment

```bash
cd ~/study/model-serving/chapters/10-kubernetes-model-deployment
bash scripts/01_check_env.sh
```

기록할 값:

| 항목 | 예시 | 내 결과 |
| --- | --- | --- |
| Kubernetes type | minikube / k3s / managed / kubeadm | |
| Kubernetes context | `model-serving` | |
| Kubernetes version | v1.33.x | |
| Node count | 1 | |
| StorageClass | `standard`, `local-path`, `gp3` 등 | |
| IngressClass | `nginx` 또는 없음 | |
| Docker | `docker --version` | |
| GPU | `nvidia-smi` 결과 또는 GPU 없음 | |

예상 확인:

- local 실습이면 `kubectl`, `docker`, `minikube`가 필요하다.
- Helm은 CPU Deployment 실습에는 필수가 아니고, NVIDIA device plugin을 Helm 방식으로 설치할 때만 필요하다.
- GPU 실습이 아니면 `nvidia-smi: not found`가 나와도 괜찮다.

## Cluster Setup

local minikube cluster를 새로 만든다면:

```bash
bash scripts/02_start_minikube.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| `kubectl get nodes -o wide`에 `model-serving` node 표시 | minikube cluster가 생성되었고 kubectl context가 연결됨 |
| `minikube addons enable ingress` 성공 | Ingress 실습도 가능 |
| `minikube addons enable ingress` 실패 | port-forward 실습은 계속 가능 |

이미 사용할 k3s, kubeadm, managed Kubernetes cluster가 있다면 이 단계는 건너뛴다.  
대신 `kubectl config current-context`가 실습 cluster를 가리키는지 반드시 확인한다.

## Image

```bash
bash scripts/03_build_and_load_image.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| `model-serving-fastapi:chapter-10` image build 성공 | 챕터 3 FastAPI 모델 서버 image가 준비됨 |
| `minikube image load` 실행 | local image가 minikube node 안으로 복사됨 |
| `minikube profile ... is not running` | 원격 cluster 또는 minikube 미사용 상황. registry image를 써야 함 |

원격 cluster 예:

```bash
IMAGE=ghcr.io/my-org/model-serving-fastapi:chapter-10 \
  bash scripts/04_apply_cpu_manifests.sh
```

## CPU Deployment

```bash
bash scripts/04_apply_cpu_manifests.sh
bash scripts/05_wait_and_inspect.sh
```

예상 Kubernetes objects:

| Object | 기대 상태 | 의미 |
| --- | --- | --- |
| Namespace `model-serving` | 존재 | 실습 리소스를 한 곳에 모음 |
| Deployment `fastapi-model-server` | `READY 1/1` | 원하는 Pod 1개가 준비됨 |
| ReplicaSet | `READY 1` | Deployment가 만든 Pod 개수를 유지 중 |
| Pod | `STATUS Running`, `READY 1/1` | 모델 서버 container가 실행 중 |
| PVC `model-cache-pvc` | `Bound` | model cache용 volume이 연결됨 |
| Service `fastapi-model-server` | `ClusterIP` | Pod 앞에 안정적인 내부 endpoint 생성 |
| Ingress | address 표시 또는 pending | controller가 있으면 HTTP route로 사용 가능 |
| Endpoint 또는 EndpointSlice | Pod IP:8000 표시 | Service가 실제 Pod를 찾고 있음 |

정상 출력 예시는 README의 `4. CPU Deployment 배포` 섹션에 있는 캡처를 참고한다.

초기 event에 아래와 같은 메시지가 한두 번 나올 수 있다.

```text
Startup probe failed ... connection refused
```

Pod가 시작되는 순간에는 FastAPI/uvicorn이 아직 port를 열지 않았을 수 있다.  
최종적으로 Pod가 `READY 1/1`이면 정상적으로 회복된 상태다.

## Service Call

터미널 1:

```bash
bash scripts/06_port_forward.sh
```

터미널 2:

```bash
bash scripts/07_curl_generate.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| `/health` 응답 | readiness/liveness probe와 같은 endpoint가 응답함 |
| `/generate` 응답 | Service를 통해 Pod의 모델 서버까지 요청이 전달됨 |
| 터미널 1을 닫으면 호출 실패 | port-forward 연결은 실행 중인 터미널에 의존함 |

## GPU Option

GPU node가 있는 cluster에서만 진행한다.

```bash
INSTALL_METHOD=helm bash scripts/08_install_nvidia_device_plugin.sh
```

또는:

```bash
INSTALL_METHOD=kubectl bash scripts/08_install_nvidia_device_plugin.sh
```

GPU node label과 taint:

```bash
kubectl label node <GPU_NODE_NAME> accelerator=nvidia
kubectl taint node <GPU_NODE_NAME> nvidia.com/gpu=true:NoSchedule
```

GPU patch:

```bash
bash scripts/09_apply_gpu_patch.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| device plugin Pod `Running` | Kubernetes가 GPU resource를 노출할 준비가 됨 |
| node allocatable에 `nvidia.com/gpu` 표시 | Pod가 GPU를 request할 수 있음 |
| Pod가 GPU node에 배치됨 | `nodeSelector`, toleration, GPU request 조건이 맞음 |
| Pod가 `Pending` | GPU node/resource/label/toleration 중 하나가 맞지 않을 수 있음 |

GPU가 없는 환경에서 `09_apply_gpu_patch.sh`를 실행하면 Pod가 `Pending`이 될 수 있다.  
이 경우는 실패라기보다 scheduler가 GPU 조건을 만족하는 node를 찾지 못했다는 학습 포인트다.

## Rolling Update

```bash
bash scripts/10_rolling_update.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| 새 ReplicaSet 생성 | Pod template 변경으로 새 revision이 만들어짐 |
| `rollout status` 성공 | 새 Pod가 ready 상태가 됨 |
| `rollout history`에 revision 추가 | rollback 가능한 이력이 남음 |
| old Pod가 순차적으로 줄어듦 | RollingUpdate 전략이 동작함 |

실패하거나 이전 상태로 되돌리고 싶다면:

```bash
kubectl -n model-serving rollout history deployment/fastapi-model-server
kubectl -n model-serving rollout undo deployment/fastapi-model-server
```

## Common Errors

| 증상 | 먼저 확인할 것 |
| --- | --- |
| `ImagePullBackOff` | image 이름, minikube image load 여부, registry 접근 권한 |
| `Pending` | node resource 부족, PVC bind 실패, GPU request 조건 |
| Service endpoint가 비어 있음 | readiness probe 실패, Service selector와 Pod label 불일치 |
| `CrashLoopBackOff` | `kubectl -n model-serving logs deploy/fastapi-model-server` |
| Ingress 호출 실패 | Ingress controller 설치 여부, `/etc/hosts`, `kubectl get ingressclass` |
| PVC가 `Pending` | StorageClass와 provisioner 상태 |
| `Startup probe failed`가 반복됨 | model server가 실제로 뜨는지, `/health` port/path가 맞는지 |

## Cleanup

```bash
bash scripts/11_cleanup.sh
```

예상 관찰:

- `model-serving` namespace와 그 안의 object가 삭제된다.
- PVC까지 삭제되므로 model cache도 사라질 수 있다.

minikube cluster 자체를 삭제하려면:

```bash
minikube delete -p model-serving
```

local Python 가상환경을 켜둔 상태라면:

```bash
deactivate
```

## Notes

- Deployment는 Pod를 직접 대체하는 것이 아니라, Pod template과 replica 수를 선언하고 ReplicaSet을 통해 Pod를 유지한다.
- Service는 바뀌는 Pod IP 앞에 고정 endpoint를 제공한다.
- Ingress object만으로는 외부 요청이 들어오지 않는다. Ingress controller가 있어야 실제 routing이 동작한다.
- PVC는 Pod 재시작과 model cache를 분리하지만, 여러 node의 replica가 같은 cache를 공유하려면 RWX storage와 file lock/write pattern을 검토해야 한다.
- GPU Pod는 `nvidia.com/gpu` request만으로 충분하지 않다. NVIDIA driver, container runtime, device plugin, node label/taint 조건을 함께 확인한다.
- 큰 LLM은 startup 시간이 길 수 있으므로 startup/readiness/liveness probe 값을 더 넉넉하게 잡아야 한다.
