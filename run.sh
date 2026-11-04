#!/bin/bash
set -euo pipefail

component="${1:?Usage: ./run.sh <frontend|mysql|catalogue>}"

case "${component}" in
  frontend|mysql|catalogue) ;;
  *)
    echo "Invalid component: ${component}" >&2
    echo "Usage: ./run.sh <frontend|mysql|catalogue>" >&2
    exit 1
    ;;
esac

cd "$(dirname "$0")"

ansible-playbook \
  -i "${component}.hdevops09.online," \
  roboshop.yml \
  -e "component_name=${component}" \
  -e "ansible_user=ec2-user" \
  -e "ansible_password=DevOps321"
