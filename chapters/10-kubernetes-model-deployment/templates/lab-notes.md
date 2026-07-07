# Chapter 10 Lab Notes

## Cluster

- Date:
- Kubernetes type: minikube / k3s / managed / kubeadm / other
- Kubernetes version:
- Node count:
- GPU node count:
- Ingress controller:
- StorageClass:

## Commands

Environment:

```bash
cd ~/study/model-serving/chapters/10-kubernetes-model-deployment
bash scripts/01_check_env.sh
```

Cluster setup:

```bash
bash scripts/02_start_minikube.sh
```

Image:

```bash
bash scripts/03_build_and_load_image.sh
```

Deploy:

```bash
bash scripts/04_apply_cpu_manifests.sh
bash scripts/05_wait_and_inspect.sh
```

Call:

```bash
bash scripts/06_port_forward.sh
bash scripts/07_curl_generate.sh
```

GPU:

```bash
INSTALL_METHOD=helm bash scripts/08_install_nvidia_device_plugin.sh
kubectl label node <GPU_NODE_NAME> accelerator=nvidia
kubectl taint node <GPU_NODE_NAME> nvidia.com/gpu=true:NoSchedule
bash scripts/09_apply_gpu_patch.sh
```

Rolling update:

```bash
bash scripts/10_rolling_update.sh
```

Cleanup:

```bash
bash scripts/11_cleanup.sh
```

## Observations

- Deployment rollout status:
- Pod scheduling result:
- Service endpoint:
- Ingress result:
- PVC status:
- Readiness behavior:
- Liveness behavior:
- Rolling update behavior:

## GPU Notes

- `nvidia-smi` result:
- Device plugin install method:
- `nvidia.com/gpu` visible on node: yes / no
- Pod placed on GPU node: yes / no
- Scheduler event if Pending:

## Questions

- What failed?
- What was confusing?
- What would change in managed Kubernetes?
- What would change for vLLM/NIM instead of the tiny FastAPI server?

