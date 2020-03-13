#! /bin/bash

# this script is intended to be executed via PRs travis CI
set -e

# 01: hacert01

echo "==========================================="
echo " Using host hacert01                       "
echo "==========================================="

cp pillar.example ci/pillar/netweaver.sls
cp ci/salt/top.sls .

cat >grains <<EOF
host: hacert01
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using host hacert02                       "
echo "==========================================="

cat >grains <<EOF
host: hacert02
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using host hacert03                       "
echo "==========================================="

cat >grains <<EOF
host: hacert03
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=ci/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using host hacert04                       "
echo "==========================================="

cat >grains <<EOF
host: hacert04
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=ci/pillar --retcode-passthrough -l debug
