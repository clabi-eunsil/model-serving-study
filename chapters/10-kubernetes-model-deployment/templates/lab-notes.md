# Chapter 10 Lab Notes

## Cluster

이번 챕터에서는 cluster 종류에 따라 관찰 결과가 조금 달라진다.  
먼저 내가 어떤 Kubernetes 환경을 사용했는지 기록한다.

```bash
kubectl version --client
kubectl config current-context
kubectl get nodes -o wide
kubectl get storageclass
kubectl get ingressclass 2>/dev/null || true
```

기록할 값:

| 항목 | 예시 | 내 결과 |
| --- | --- | --- |
| Kubernetes type | minikube / k3s / managed / kubeadm | |
| Kubernetes version | v1.33.x | |
| Node count | 1 | |
| GPU node count | 0 또는 1+ | |
| Ingress controller | minikube ingress / nginx / none | |
| StorageClass | standard / local-path / gp3 등 | |

## Commands

Environment:

```bash
cd ~/study/model-serving/chapters/10-kubernetes-model-deployment
bash scripts/01_check_env.sh
```

정상 관찰:

- `kubectl current-context`가 실습 cluster를 가리킨다.
- `kubectl get nodes`가 성공한다.
- Docker image build를 해야 하므로 `docker --version`이 출력된다.
- GPU 실습이 아니면 `nvidia-smi: not found`가 나와도 괜찮다.

Cluster setup:

```bash
bash scripts/02_start_minikube.sh
```

minikube를 쓰는 경우 정상 관찰:

- `kubectl get nodes -o wide`에 `model-serving` node가 보인다.
- `minikube addons enable ingress`가 실패해도 port-forward 실습은 진행할 수 있다.

Image:

```bash
bash scripts/03_build_and_load_image.sh
```

정상 관찰:

- `model-serving-fastapi:chapter-10` image가 build된다.
- minikube 사용 시 `minikube image load`가 실행된다.
- 원격 cluster라면 이 단계 대신 registry push image를 사용해야 한다.

Deploy:

```bash
bash scripts/04_apply_cpu_manifests.sh
bash scripts/05_wait_and_inspect.sh
```

정상 관찰:

- Deployment `fastapi-model-server`가 `1/1` ready가 된다.
- PVC `model-cache-pvc`가 `Bound` 상태가 된다.
- Service `fastapi-model-server`가 생성된다.
- Endpoints에 Pod IP와 `8000` port가 보인다.

문제 해석:

| 증상 | 먼저 볼 것 |
| --- | --- |
| `ImagePullBackOff` | image 이름, minikube image load 여부, registry 접근 권한 |
| `Pending` | node resource 부족, PVC bind 실패, GPU request 조건 |
| endpoint가 비어 있음 | readiness probe 실패, Service selector와 Pod label 불일치 |
| `CrashLoopBackOff` | `kubectl -n model-serving logs deploy/fastapi-model-server` |

Call:

```bash
bash scripts/06_port_forward.sh
bash scripts/07_curl_generate.sh
```

정상 관찰:

- `06_port_forward.sh`는 터미널을 점유한다. 닫으면 local endpoint도 끊긴다.
- `07_curl_generate.sh`에서 `/health`와 `/generate` 응답이 출력된다.

GPU:

```bash
INSTALL_METHOD=helm bash scripts/08_install_nvidia_device_plugin.sh
kubectl label node <GPU_NODE_NAME> accelerator=nvidia
kubectl taint node <GPU_NODE_NAME> nvidia.com/gpu=true:NoSchedule
bash scripts/09_apply_gpu_patch.sh
```

GPU 실습 전 확인:

```bash
nvidia-smi
kubectl describe node <GPU_NODE_NAME> | grep -A5 "nvidia.com/gpu"
kubectl get nodes -L accelerator
```

정상 관찰:

- NVIDIA device plugin Pod가 Running 상태다.
- GPU node의 allocatable에 `nvidia.com/gpu`가 보인다.
- GPU patch 적용 후 Pod가 GPU node에 배치된다.

GPU가 없는 환경에서 `09_apply_gpu_patch.sh`를 실행하면 Pod가 `Pending`이 될 수 있다.  
이때는 실패라기보다 scheduler가 GPU 조건을 만족하는 node를 찾지 못했다는 뜻이다.

Rolling update:

```bash
bash scripts/10_rolling_update.sh
```

정상 관찰:

- 새 ReplicaSet이 생긴다.
- 새 Pod가 ready 되기 전까지 기존 Pod가 바로 내려가지 않는다.
- `kubectl rollout history deployment/fastapi-model-server`에 revision이 추가된다.

Cleanup:

```bash
bash scripts/11_cleanup.sh
```

정상 관찰:

- `model-serving` namespace와 그 안의 object가 삭제된다.
- PVC까지 삭제되므로 model cache도 사라질 수 있다.

minikube cluster 자체를 삭제하려면:

```bash
minikube delete -p model-serving
```

## 관찰 정리

| 항목 | 무엇을 봤는가 |
| --- | --- |
| Deployment rollout | |
| Pod scheduling result | |
| Service endpoint | |
| Ingress result | |
| PVC status | |
| Readiness behavior | |
| Liveness behavior | |
| Rolling update behavior | |
| GPU device plugin result | |
| `nvidia.com/gpu` visible on node | yes / no |
| Pod placed on GPU node | yes / no |
| Scheduler event if Pending | |

## 생각해 볼 질문

- Pod를 직접 만들지 않고 Deployment를 쓰는 이유는 무엇인가?
- Service가 없으면 Pod IP로 직접 호출할 때 어떤 문제가 생기는가?
- Ingress object와 Ingress controller는 왜 둘 다 필요한가?
- GPU node에 `nvidia.com/gpu`가 보이지 않는다면 어느 계층부터 확인해야 하는가?
- `nodeSelector`와 toleration은 각각 어떤 방향의 조건인가?
- 모델 로딩이 오래 걸리는 서버에서 liveness probe를 너무 짧게 두면 어떤 일이 생기는가?
- PVC를 쓰면 image size와 cold start에 어떤 영향을 줄 수 있는가?
- vLLM/NIM을 올린다면 CPU/memory/GPU/PVC/probe 중 무엇을 가장 먼저 바꿔야 할까?
