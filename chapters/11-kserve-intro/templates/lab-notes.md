# Chapter 11 Lab Notes

## Sources

- KServe Quickstart Guide: https://kserve.github.io/website/docs/getting-started/quickstart-guide
- KServe Standard mode installation: https://kserve.github.io/website/docs/admin-guide/kubernetes-deployment
- KServe Knative mode installation: https://kserve.github.io/website/docs/admin-guide/serverless
- KServe Architecture: https://kserve.github.io/website/docs/concepts/architecture
- KServe Resources: https://kserve.github.io/website/docs/concepts/resources
- Predictive InferenceService tutorial: https://kserve.github.io/website/docs/getting-started/predictive-first-isvc
- Knative serverless installation guide: https://kserve.github.io/website/docs/admin-guide/serverless
- ServingRuntime resources: https://kserve.github.io/website/docs/concepts/resources/servingruntime

## KServe 설치

이번 스터디의 기본 선택은 KServe Quickstart standard mode다.

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

| 항목 | 의미 | 정상/주의 기준 |
| --- | --- | --- |
| 현재 context | KServe를 설치할 cluster | 개인 minikube/kind인지, 원격 공유 cluster인지 반드시 확인 |
| official install URL | KServe release script | `v0.18.0` standard mode script인지 확인 |
| `CONFIRM_INSTALL_KSERVE` | 실제 설치 여부 | 기본값은 dry-run, `true`일 때만 설치 |
| 설치 후 CRD | KServe API 확장 여부 | `inferenceservices.serving.kserve.io`가 보여야 함 |
| 설치 후 runtime | 기본 runtime 설치 여부 | sklearn 계열 runtime이 보여야 이번 장 예제 가능 |

공유 cluster에서는 이 스크립트를 바로 실행하지 않는다. KServe 설치는 cluster 전체 CRD와 controller를 바꾸는 작업이다.

## 실행 환경

```bash
cd ~/study/model-serving/chapters/11-kserve-intro
bash scripts/01_check_env.sh
```

기록할 값:

| 항목 | 예시 | 내 결과 |
| --- | --- | --- |
| Kubernetes context | `model-serving` / remote cluster | |
| Kubernetes version | v1.32+ | |
| KServe version | 0.18 등 | |
| KServe mode | standard / knative / unknown | |
| Gateway layer | Istio / Kourier / other | |
| sklearn runtime visible | yes / no | |

예상 확인:

- `InferenceService CRD: installed`가 보이면 KServe CRD가 설치되어 있다.
- `ClusterServingRuntime` 목록에 sklearn 계열 runtime이 보이면 sklearn 예제를 실행할 수 있다.
- `istio-system` service가 없으면 port-forward script에서 gateway service를 찾지 못할 수 있다.

## Namespace

```bash
bash scripts/02_prepare_namespace.sh
```

예상 관찰:

- namespace `kserve-test`가 생성된다.
- control plane namespace가 아닌 별도 namespace에 실습 리소스를 배포한다.

## InferenceService

```bash
bash scripts/03_apply_sklearn_iris.sh
bash scripts/04_wait_and_inspect.sh
```

예상 관찰:

| 항목 | 의미 |
| --- | --- |
| `InferenceService` `READY True` | KServe가 model serving 리소스를 준비함 |
| `status.url` 생성 | gateway/route를 통해 호출할 hostname이 생김 |
| predictor Pod Running | runtime container가 모델을 serving 중 |
| `ksvc`, `revision`, `route` 표시 | Knative mode에서 생성되는 리소스 |
| Deployment/Service 표시 | standard mode 또는 하위 Kubernetes 리소스 |

## Request

```bash
bash scripts/05_prepare_request.sh
```

요청 의미:

| field | 의미 |
| --- | --- |
| `instances` | batch inference 입력 row 목록 |
| `[6.8, 2.8, 4.8, 1.4]` | iris feature vector |
| response `predictions` | model이 예측한 class index |

## Predict Call

터미널 1:

```bash
bash scripts/06_port_forward_gateway.sh
```

터미널 2:

```bash
bash scripts/07_curl_predict.sh
```

예상 관찰:

- `SERVICE_HOSTNAME`이 `sklearn-iris.kserve-test...` 형태로 출력된다.
- curl 요청에는 `Host: ${SERVICE_HOSTNAME}` header가 포함된다.
- 응답에 `predictions`가 포함된다.

## Autoscaling

```bash
bash scripts/08_check_autoscaling.sh
```

볼 것:

| 항목 | 의미 |
| --- | --- |
| `ksvc` | Knative service 상태 |
| `revision` | model server revision |
| `kpa` 또는 autoscaler 관련 리소스 | Knative autoscaling 리소스 |
| Pod 수 변화 | traffic 유무에 따른 scale 동작 |

standard mode에서는 scale-to-zero 리소스가 보이지 않을 수 있다.
그 경우에도 이상한 것이 아니라 설치 mode 차이다.

mode별로 다르게 보이는 이유:

| mode | 왜 다르게 보이나 |
| --- | --- |
| Standard mode | Kubernetes `Deployment`와 Pod가 중심이라 Knative `ksvc`, `revision`, `kpa`가 없을 수 있다. |
| Knative mode | Knative가 request 기반 autoscaling과 scale-to-zero를 담당하므로 Knative 관련 리소스가 함께 보인다. |

작은 sklearn 모델에서는 scale-to-zero 후 다시 뜨는 시간이 짧을 수 있다.
하지만 LLM은 model download, GPU loading, KV cache 준비 때문에 같은 전략을 그대로 쓰면 첫 요청 지연이 커질 수 있다.

## Common Errors

| 증상 | 먼저 확인할 것 |
| --- | --- |
| `InferenceService CRD: not found` | KServe가 설치되어 있는지 |
| `sklearn` runtime이 없음 | `kubectl get clusterservingruntime` |
| `InferenceService`가 Ready가 되지 않음 | `kubectl describe inferenceservice`, events, predictor Pod logs |
| storage initializer 실패 | `storageUri`, network, cloud storage 접근 권한 |
| gateway service를 못 찾음 | `kubectl get svc -n istio-system`, 설치 mode |
| curl 404/503 | Host header, gateway port-forward, `status.url` hostname |
| autoscaling 리소스가 없음 | standard mode인지 Knative mode인지 확인 |

## 정리

```bash
bash scripts/09_cleanup.sh
```

예상 관찰:

- namespace `kserve-test`가 삭제된다.
- 그 안의 `InferenceService`, Pod, route 관련 리소스가 함께 정리된다.

## Notes

- KServe는 Kubernetes를 대체하지 않고, Kubernetes 위에 model serving용 CRD와 controller를 추가한다.
- `InferenceService`는 model serving 의도를 선언하고, KServe control plane이 하위 리소스를 맞춘다.
- predictor는 실제 inference를 수행한다.
- transformer는 전처리/후처리, explainer는 설명 가능성 component다.
- Knative mode의 scale-to-zero는 CPU predictive model에는 유용하지만, 큰 LLM처럼 startup 비용이 큰 workload에는 조심해야 한다.
- 챕터 12에서는 KServe로 LLM을 serving할 때 custom runtime, GPU, storage initializer, OpenAI-compatible endpoint 문제를 이어서 본다.
