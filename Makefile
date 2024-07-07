.PHONY: kc_patch_pod min_start kc_debug_pod kc_debug_node

kc_to_yaml:
	kubectl get pod $(pod) -n $(ns) -o yaml > $(pod).yaml

kc_patch_pod:
	kubectl patch pod kube-apiserver-minikube -n kube-system --patch-file kube-apiserver.yaml

kc_debug_pod:
	@echo "Building debugging pod to pod: $(pod)"
	kubectl debug $(pod) -it --image=busybox -- sh

kc_debug_node:
	@echo "Building debugging pod to node: $(node)"
	kubectl debug $(node) -it --image=busybox -- sh

min_start:
	@echo "Building Minikube with $(K_VS)"
#minikube start --memory 8182 --cpus 4 --kubernetes-version=v$(K_VS)
	minikube start --memory 15842 --cpus 8 --kubernetes-version=v$(K_VS) \
		--feature-gates=InPlacePodVerticalScaling=true \
		--extra-config=controller-manager.horizontal-pod-autoscaler-upscale-delay=1m \
  	--extra-config=controller-manager.horizontal-pod-autoscaler-downscale-delay=2m \
  	--extra-config=controller-manager.horizontal-pod-autoscaler-sync-period=10s

kc_pf_grafana:
#kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &> kubectl-port-forward.log &
	nohup kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &> kubectl-port-forward.log &

kc_pods_metrics:
	@echo "Getting pod metrics json with jq..."
	kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods" | jq .

kc_node_metrics:
	@echo "Getting NODE metrics json with jq..."
	kubectl get --raw "/apis/metrics.k8s.io/v1beta1/node" | jq .

# kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq .

kc_res_lim_ns:
	@echo "Creating resource limited namespace"
	kubectl apply -f manifests/ns-tools/resource-limited-ns.yaml
