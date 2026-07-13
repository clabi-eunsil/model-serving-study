# Chapter 11 Lab Notes

## Sources

- KServe Quickstart Guide: https://kserve.github.io/website/docs/getting-started/quickstart-guide
- KServe Standard mode installation: https://kserve.github.io/website/docs/admin-guide/kubernetes-deployment
- KServe Knative mode installation: https://kserve.github.io/website/docs/admin-guide/serverless
- KServe Architecture: https://kserve.github.io/website/docs/concepts/architecture
- KServe Resources: https://kserve.github.io/website/docs/concepts/resources
- Predictive InferenceService tutorial: https://kserve.github.io/website/docs/getting-started/predictive-first-isvc
- ServingRuntime resources: https://kserve.github.io/website/docs/concepts/resources/servingruntime

## Environment

```bash
cd ~/study/model-serving/chapters/11-kserve-intro
bash scripts/01_check_env.sh
```

예상 확인:

| 항목 | 의미 | 정상 해석 |
| --- | --- | --- |
| current context | 지금 `kubectl`이 바라보는 cluster | `model-serving`처럼 실습용 cluster여야 안전하다. |
| node `Ready` | Kubernetes node가 동작 중인지 | node가 `Ready`면 기본 cluster 연결은 정상이다. |
| InferenceService CRD | KServe API가 설치되었는지 | `InferenceService CRD: installed`면 KServe CRD가 있다. |
| KServe controller | KServe control plane 상태 | `kserve-controller-manager`가 `Running`이면 controller가 동작 중이다. |
| ServingRuntime | 모델을 실행할 runtime 목록 | `kserve-sklearnserver`가 보여야 sklearn 예제를 진행할 수 있다. |
| Networking layer | 외부 요청을 받을 ingress/gateway | local standard mode에서는 `ingress-nginx-controller`가 보일 수 있다. |

중요한 해석:

- KServe CRD와 controller가 있어도 `ServingRuntime`이 비어 있으면 아직 모델을 실행할 runtime이 없는 상태다.
- `ingress-nginx`가 보이고 `istio-system`이 없어도 standard mode 실습에서는 이상하지 않다.
- 이번 장은 Knative mode가 아니라 standard mode를 기준으로 진행한다.

## KServe 설치

설치 명령 확인:

```bash
bash scripts/00_install_kserve_quickstart_standard.sh
```

실제 설치:

```bash
CONFIRM_INSTALL_KSERVE=true \
bash scripts/00_install_kserve_quickstart_standard.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| KServe version | 실습에서 사용하는 KServe release version |
| install script URL | 공식 release script 위치 |
| current context | 설치 대상 cluster |
| node 상태 | 설치 가능한 Kubernetes cluster인지 |
| `CONFIRM_INSTALL_KSERVE` | 실제 설치를 진행할지 결정하는 안전장치 |

주의:

- 공유 cluster에서는 이 스크립트를 바로 실행하지 않는다.
- KServe 설치는 CRD, controller, webhook, networking 관련 리소스를 cluster 단위로 만든다.
- Helm이 없어도 설치 방식에 따라 진행될 수 있지만, 관련 chart 설치나 운영 설치를 보려면 Helm을 준비하는 편이 좋다.

## Default ServingRuntime

KServe controller가 설치되어도 runtime 목록이 비어 있을 수 있다.

```bash
kubectl get clusterservingruntime
```

아래처럼 나오면 runtime이 아직 없는 상태다.

```text
No resources found
```

이 경우 default runtime을 적용한다.

```bash
bash scripts/00_apply_kserve_default_runtimes.sh
```

실제 적용:

```bash
CONFIRM_APPLY_RUNTIMES=true \
bash scripts/00_apply_kserve_default_runtimes.sh
```

예상 runtime:

| runtime | 의미 |
| --- | --- |
| `kserve-sklearnserver` | sklearn model artifact를 실행할 runtime |
| `kserve-xgbserver` | XGBoost model용 runtime |
| `kserve-tritonserver` | Triton Inference Server runtime |
| `kserve-huggingfaceserver` | Hugging Face 계열 model runtime |

이번 sklearn iris 예제는 `kserve-sklearnserver` 또는 sklearn을 지원하는 runtime이 필요하다.

## Namespace

```bash
bash scripts/02_prepare_namespace.sh
```

예상 관찰:

- `kserve-test` namespace가 생성된다.
- control plane namespace인 `kserve`와 실습 namespace를 분리한다.

## InferenceService

```bash
bash scripts/03_apply_sklearn_iris.sh
bash scripts/04_wait_and_inspect.sh
```

정상 해석:

| 출력 | 의미 |
| --- | --- |
| `READY True` | KServe가 predictor 리소스를 준비했다. |
| `status.url` | gateway/ingress를 통해 호출할 hostname이다. |
| `Deployment sklearn-iris-predictor` | standard mode에서 만들어진 실제 실행 리소스다. |
| `Service sklearn-iris-predictor` | predictor Pod 앞의 Kubernetes Service다. |
| `Pod Running` | sklearn runtime container가 떠 있다. |

이번 실습 manifest에는 아래 annotation이 들어 있다.

```yaml
serving.kserve.io/deploymentMode: Standard
```

이 annotation이 중요한 이유:

- 현재 local 실습은 Knative가 없는 standard mode cluster다.
- annotation이 없으면 KServe config에 따라 Knative mode로 만들어질 수 있다.
- Knative mode로 만들어졌는데 Knative가 없으면 `ServerlessModeRejected` event가 나오고 Pod가 생성되지 않는다.

이미 Knative mode로 잘못 만들어진 경우:

```bash
CONFIRM_RECREATE_ISVC=true \
bash scripts/03_apply_sklearn_iris.sh
```

KServe는 `deploymentMode`를 in-place update로 바꾸는 것을 허용하지 않는다.  
그래서 기존 `InferenceService`를 삭제하고 다시 만들어야 한다.

## Request Payload

```bash
bash scripts/05_prepare_request.sh
```

이 단계는 요청을 보내는 단계가 아니다.  
`07_curl_predict.sh`가 보낼 JSON 파일을 먼저 확인하는 단계다.

요청 형태:

```json
{
  "instances": [
    [6.8, 2.8, 4.8, 1.4],
    [6.0, 3.4, 4.5, 1.6]
  ]
}
```

해석:

| 항목 | 의미 |
| --- | --- |
| `instances` | 한 번에 예측할 입력 row 목록 |
| row 하나 | iris 꽃 하나의 feature vector |
| 숫자 4개 | sepal length, sepal width, petal length, petal width |
| `predictions` | model이 예측한 class index |

이번 단계의 목적은 "predictive model은 정해진 schema의 feature 값을 받아 예측한다"는 흐름을 확인하는 것이다.

## Predict Call

터미널 1:

```bash
bash scripts/06_port_forward_gateway.sh
```

터미널 2:

```bash
bash scripts/07_curl_predict.sh
```

정상 응답:

```text
HTTP/1.1 200 OK
{"predictions":[1,1]}
```

해석:

- `SERVICE_HOSTNAME`은 KServe `status.url`에서 가져온 hostname이다.
- TCP 연결은 `127.0.0.1:8080`으로 가지만, route 선택은 `Host` header가 결정한다.
- `predictions`가 오면 ingress-nginx, KServe Ingress, predictor Service, sklearn runtime Pod까지 요청이 도달한 것이다.

## nginx 404

아래처럼 나오면 예측 성공이 아니다.

```text
HTTP/1.1 404 Not Found
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
```

해석:

- 요청은 `ingress-nginx`까지 도달했다.
- 하지만 nginx가 KServe가 만든 Ingress route를 처리하지 않았다.
- 흔한 원인은 `IngressClass`가 맞지 않는 것이다.

확인:

```bash
kubectl get ingressclass
kubectl get ingress -A -o wide
```

`IngressClass`는 `nginx`인데 `sklearn-iris` Ingress의 `CLASS`가 `istio`이면 KServe 설정을 맞춘다.

```bash
bash scripts/00_patch_kserve_standard_ingress_nginx.sh
```

실제 patch:

```bash
CONFIRM_PATCH_KSERVE_INGRESS=true \
bash scripts/00_patch_kserve_standard_ingress_nginx.sh
```

patch 후 확인:

```bash
kubectl get ingress -A -o wide
bash scripts/07_curl_predict.sh
```

`CLASS`가 `nginx`이고 `{"predictions":[1,1]}`가 오면 해결된 것이다.

## Autoscaling

```bash
bash scripts/08_check_autoscaling.sh
```

이번 standard mode 실습의 정상 해석:

| 출력 | 의미 |
| --- | --- |
| `Knative resources`가 비어 있음 | 현재 실습은 Knative mode가 아니다. 문제 상황이 아니다. |
| `Autoscaling resources`가 비어 있음 | 이번 실습에서는 HPA/KPA autoscaling을 따로 구성하지 않았다. |
| `sklearn-iris-predictor` Pod가 `Running` | predictor Pod 1개가 계속 떠 있는 standard mode 상태다. |

정리하면, 이번 장에서는 scale-to-zero를 확인하지 않는다.  
scale-to-zero를 보려면 Knative mode로 KServe를 설치한 cluster에서 별도 실습이 필요하다.

## Common Errors

| 증상 | 의미 | 먼저 볼 것 |
| --- | --- | --- |
| `InferenceService CRD: not found` | KServe가 아직 설치되지 않음 | `00_install_kserve_quickstart_standard.sh` |
| `ServingRuntime`이 비어 있음 | modelFormat을 실행할 runtime이 없음 | `00_apply_kserve_default_runtimes.sh` |
| `ServerlessModeRejected` | Knative mode로 만들었지만 Knative가 없음 | `deploymentMode: Standard` annotation |
| `deploymentMode cannot be changed` | 기존 InferenceService mode를 직접 바꾸려 함 | `CONFIRM_RECREATE_ISVC=true`로 재생성 |
| nginx `404 Not Found` | ingress까지 갔지만 route 매칭 실패 | IngressClass, `00_patch_kserve_standard_ingress_nginx.sh` |
| `predictions`가 없음 | predictor까지 요청이 가지 않았을 수 있음 | Host header, port-forward, Ingress, Pod log |
| autoscaling 리소스가 없음 | standard mode에서는 자연스러울 수 있음 | `08_check_autoscaling.sh` 해석 |

## Cleanup

챕터 11 실습 namespace만 정리:

```bash
bash scripts/09_cleanup.sh
```

예상 관찰:

- `kserve-test` namespace가 삭제된다.
- 그 안의 `InferenceService`, Deployment, Service, Pod, Ingress가 함께 정리된다.
- KServe controller, runtime, minikube cluster는 남아 있다.

minikube를 잠시 멈추기:

```bash
minikube stop -p model-serving
```

minikube cluster까지 완전히 삭제:

```bash
minikube delete -p model-serving
```

가상환경 종료:

```bash
deactivate
```

## Notes

- KServe는 Kubernetes를 대체하지 않고, Kubernetes 위에 model serving용 CRD와 controller를 추가한다.
- `InferenceService`는 model serving 의도를 선언하고, KServe control plane이 하위 리소스를 만든다.
- `ServingRuntime`은 model artifact를 실행할 container 정의다.
- `storageUri`는 model artifact가 저장된 위치다.
- 이번 장에서는 predictor만 사용했다. transformer와 explainer는 개념만 확인했다.
- standard mode는 Kubernetes Deployment/Service/Ingress 흐름과 연결된다.
- Knative mode는 request 기반 autoscaling과 scale-to-zero를 볼 때 따로 다룬다.
- 챕터 12에서는 KServe로 LLM을 serving하면서 custom runtime, GPU, Hugging Face model URI, OpenAI-compatible endpoint를 이어서 본다.
