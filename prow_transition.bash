#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

cleanup() {
  kind delete cluster --name=prow-stats > /dev/null
}

# trap cleanup EXIT ERR

#echo "Creating cluster, please wait.."
#kind create cluster -q --name=prow-stats 
#flux install \
#    --namespace=flux-system \
#    --network-policy=false \
#    --components=source-controller,helm-controller 
#kubectl apply -f https://raw.githubusercontent.com/cncf-infra/infrasnoop/canon/manifests/infrasnoop.yaml
#sleep 3
#kubectl wait --for=condition=ready pod/infrasnoop-0 -n default

#kubectl cp -n default ./load_data.bash infrasnoop-0:/tmp/

kubectl exec -it pod/infrasnoop-0 -n default -- /bin/bash <<'EOF'
echo "Loading data, please wait.."
psql -U infrasnoop -h infrasnoop -c "select * from add_prow_deck_jobs();" 
psql -U infrasnoop -h infrasnoop -c "select * from load_sigs_tables();" 
/tmp/load_data.bash

psql -U infrasnoop -h infrasnoop -c "SELECT
  cluster,
  count(*) AS count,
  CONCAT(ROUND(count(*) * 100.0 / SUM(count(*)) OVER (), 2), '%') AS percentage
FROM prow.job_spec
GROUP BY cluster
ORDER BY count(*) DESC;"

echo "total: (`psql -U infrasnoop -h infrasnoop -At -c 'SELECT SUM(count(*)) OVER () FROM prow.job_spec;'`)"
EOF
