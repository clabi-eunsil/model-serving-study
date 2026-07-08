# References

KServe, Knative, Istio, Gateway, cert-manager, model runtime 구성은 버전 변화가 잦다.  
실습 전 공식 문서를 다시 확인한다.

## 공식 문서

| 주제 | URL | 주요하게 볼 부분 |
| --- | --- | --- |
| KServe Quickstart Guide | https://kserve.github.io/website/docs/getting-started/quickstart-guide | KServe 0.18 기준 Kubernetes version requirement, standard mode와 Knative mode 설치 방식, quickstart 흐름을 본다. |
| KServe Architecture Overview | https://kserve.github.io/website/docs/concepts/architecture | control plane과 data plane의 역할, standard mode와 Knative mode 차이를 확인한다. |
| KServe Resources | https://kserve.github.io/website/docs/concepts/resources | `InferenceService`, `ServingRuntime`, `ClusterServingRuntime`, storage 관련 CRD 관계를 본다. |
| Predictive InferenceService tutorial | https://kserve.github.io/website/docs/getting-started/predictive-first-isvc | sklearn iris InferenceService YAML, status 확인, gateway/Host header 호출 방식을 본다. |
| Predictive Inference Frameworks Overview | https://kserve.github.io/website/docs/model-serving/predictive-inference/frameworks/overview | KServe가 built-in runtime으로 지원하는 framework와 model format을 확인한다. |
| ServingRuntime resources | https://kserve.github.io/website/docs/concepts/resources/servingruntime | ServingRuntime과 ClusterServingRuntime이 model server container를 정의하는 방식을 본다. |
| Knative Serverless Installation Guide | https://kserve.github.io/website/docs/admin-guide/serverless | Knative mode, autoscaling, scale-to-zero가 어떤 구성요소를 필요로 하는지 확인한다. |
| Kubernetes Custom Resources | https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/ | KServe가 CRD와 controller로 Kubernetes API를 확장한다는 배경을 이해한다. |
| kubectl JSONPath | https://kubernetes.io/docs/reference/kubectl/jsonpath/ | `status.url` 같은 field를 script에서 추출하는 방법을 본다. |
| Kubernetes Service | https://kubernetes.io/docs/concepts/services-networking/service/ | KServe 하위에서 만들어지는 Service와 routing의 Kubernetes 기본 개념을 복습한다. |

## 업데이트 가능성이 큰 정보

- KServe installation mode와 요구 Kubernetes version은 release에 따라 달라질 수 있다.
- KServe 0.18 이후 standard mode, Knative mode, Gateway API 관련 권장 구성이 바뀔 수 있다.
- built-in runtime 목록과 runtime image tag는 release마다 추가/변경될 수 있다.
- sklearn iris 예제의 public `storageUri`나 gateway 호출 예시는 문서 개편에 따라 바뀔 수 있다.
- Knative/Istio/Gateway/cert-manager 설치 방식은 cluster 환경과 provider에 따라 달라진다.
- autoscaling과 scale-to-zero 동작은 KServe mode, Knative 설정, traffic pattern에 따라 다르게 보일 수 있다.
- LLM serving은 다음 챕터에서 다루며, KServe predictive example과 resource 요구사항이 크게 다르다.
