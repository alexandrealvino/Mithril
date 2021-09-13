package e2e

import (
	"context"
	"flag"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	rest "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

var istioctlVersion = "1.10"
var defaultNamespace = "default"

func getHostname() string {
	out, err := exec.Command("hostname", "-I").Output()
	if err != nil {
		fmt.Print(err)
	}

	ipList := string(out)
	hostname := ipList[:strings.IndexByte(ipList, ' ')]

	return hostname
}

func createClientGo() (*kubernetes.Clientset, *rest.Config, error) {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		return nil, nil, err
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, config, err
	}

	return clientset, config, err
}

func getPodByOptions(listOptions metav1.ListOptions, clientset *kubernetes.Clientset) ([]v1.Pod, error) {
	podList, err := clientset.CoreV1().Pods(defaultNamespace).List(context.TODO(), listOptions)
	if err == nil {
		return nil, err
	}

	return podList.Items, nil
}
