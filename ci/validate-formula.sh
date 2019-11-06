#! /bin/bash

# this script is intended to be executed via PRs travis CI
set -e

# 01: hacert01

echo "==========================================="
echo " Using sapha1as                            "
echo "==========================================="

cp pillar.example ci/pillar/netweaver.sls
cp ci/salt/top.sls .

cat >grains <<EOF
host: hacert01
virtual_host: sapha1as
sap_instance: ascs
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using sapha1er                            "
echo "==========================================="

cat >grains <<EOF
host: hacert02
virtual_host: sapha1er
sap_instance: ers
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using sapha1db                           "
echo "==========================================="

cat >grains <<EOF
host: hacert03
virtual_host: sapha1db
sap_instance: db
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root==ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using sapha1pas                           "
echo "==========================================="

cat >grains <<EOF
host: hacert03
virtual_host: sapha1pas
sap_instance: pas
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root==ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using sapha1aas                           "
echo "==========================================="

cat >grains <<EOF
host: hacert04
virtual_host: sapha1aas
sap_instance: aas
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root==ci/pillar --retcode-passthrough -l debug