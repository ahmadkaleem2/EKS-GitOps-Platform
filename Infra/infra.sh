#!/bin/bash
set -e

ACTION=$1

if [[ -z "$ACTION" ]]; then
  echo "Usage: ./infra.sh [create|destroy]"
  exit 1
fi

create_infra() {
  echo "Creating infrastructure..."

  cd networking
  terraform apply -auto-approve

  cd ../eks
  terraform apply -auto-approve

  cd ../add_ons
  terraform apply -auto-approve

  cd ../argocd
  terraform apply -auto-approve

  aws eks update-kubeconfig --region us-east-1 --name Ahmad-EKS

  argocd_initial_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o=jsonpath='{.data.password}' | base64 -d)
  echo "ArgoCD initial admin password: $argocd_initial_password"

  kubectl apply -f ./manifests/

  echo "Infrastructure creation complete."
}

destroy_infra() {
  echo "Destroying infrastructure..."

  cd argocd
  terraform destroy -auto-approve

  cd ../add_ons
  terraform destroy -auto-approve

  cd ../eks
  terraform destroy -auto-approve

  cd ../networking
  terraform destroy -auto-approve

  echo "Infrastructure destroyed."
}

case "$ACTION" in
  create)
    create_infra
    ;;
  destroy)
    destroy_infra
    ;;
  *)
    echo "Invalid option: $ACTION"
    echo "Usage: ./infra.sh [create|destroy]"
    exit 1
    ;;
esac