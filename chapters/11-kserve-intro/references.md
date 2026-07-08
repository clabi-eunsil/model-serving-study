# Chapter 11 References

이 문서는 2026-07-08 기준 KServe 0.18 공식 문서를 바탕으로 작성했다.  
KServe는 Kubernetes, Knative, Istio, Gateway, cert-manager, model runtime 버전의 영향을 크게 받으므로 실습 전 공식 문서를 다시 확인한다.

## KServe 공식 문서

- Quickstart Guide: https://kserve.github.io/website/docs/getting-started/quickstart-guide
- System Architecture Overview: https://kserve.github.io/website/docs/concepts/architecture
- KServe Resources: https://kserve.github.io/website/docs/concepts/resources
- Deploy Your First Predictive InferenceService: https://kserve.github.io/website/docs/getting-started/predictive-first-isvc
- Predictive Inference Frameworks Overview: https://kserve.github.io/website/docs/model-serving/predictive-inference/frameworks/overview
- Knative Serverless Installation Guide: https://kserve.github.io/website/docs/admin-guide/serverless
- ServingRuntime resources: https://kserve.github.io/website/docs/concepts/resources/servingruntime

## 함께 확인할 Kubernetes 문서

- Custom Resources: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- kubectl JSONPath: https://kubernetes.io/docs/reference/kubectl/jsonpath/
- Services, Load Balancing, and Networking: https://kubernetes.io/docs/concepts/services-networking/service/

## 무엇을 중점적으로 볼 것인가

| 문서 | 먼저 볼 부분 |
| --- | --- |
| Quickstart Guide | KServe 0.18 기준 Kubernetes version requirement, standard mode와 Knative mode 설치 방식 |
| Architecture Overview | control plane과 data plane 분리, standard mode와 Knative mode 차이 |
| Resources | `InferenceService`, `ServingRuntime`, `ClusterServingRuntime`, storage 관련 CRD 관계 |
| Predictive first ISVC | sklearn iris InferenceService YAML, status 확인, gateway/Host header 호출 방식 |
| Frameworks Overview | built-in runtime이 어떤 framework를 지원하는지 |
| Knative Serverless | autoscaling, scale-to-zero가 어떤 상황에 적합한지와 LLM에는 standard mode가 권장되는 이유 |
