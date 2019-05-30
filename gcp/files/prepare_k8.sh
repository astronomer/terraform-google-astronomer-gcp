export KUBECONFIG=/opt/astronomer/kubeconfig
/snap/bin/kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
/snap/bin/kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
/snap/bin/helm init --service-account tiller --upgrade

