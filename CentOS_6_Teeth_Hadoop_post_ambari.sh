#!/usr/bin/env bash
###############################################################################
# Ambari Server/Agent Setup for CentOS                                        #
###############################################################################
#                                                                             #
# This script provides all the functionality to setup the necessary packages  #
# for Ambari Server/Agent on CentOS                                           #
#                                                                             #
###############################################################################

AMBARI_VERSION=${AMBARI_VERSION:-"2.1.1"}
HDP_VERSION=${HDP_VERSION:-"2.2.6.0"}


function setup_repos() {
    set -e
    wget -O /etc/yum.repos.d/ambari.repo http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/${AMBARI_VERSION}/ambari.repo
    wget -O /etc/yum.repos.d/hdp.repo http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/${HDP_VERSION}/hdp.repo

    # Switch to our local mirror
#    sed -i "s/public-repo-1.hortonworks.com/mirrors.dev.cbd.rackspace.com\/hortonworks/g" /etc/yum.repos.d/ambari.repo
#    sed -i "s/public-repo-1.hortonworks.com/mirrors.dev.cbd.rackspace.com\/hortonworks/g" /etc/yum.repos.d/hdp.repo

    cat <<EOF > /etc/yum.repos.d/rackspace-cbd.repo
[rackspace-cbd]
name=Rackspace-CBD-$releasever - Base
baseurl=http://mirrors.dev.cbd.rackspace.com/cbd/rhel/
gpgcheck=0
EOF
    set +e
}

function fix_requests() {
    # when python-requests is updated, it doesn't clean up the old version properly and breaks
    # cloud-init, so we clean it up manually
    # https://bugs.centos.org/view.php?id=9139
    yum remove -y python-requests
    rm -rf /usr/lib/python2.6/site-packages/requests/
    yum install -y python-requests
}

function yum_refresh() {
    rm -rf /var/cache/yum
    yum -y check-update
}

function yum_update() {
    yum_refresh
    yum -y update
    yum_refresh
}

function install_xfs_progs() {
    echo "Installing xfsprogs"
    yum -y install xfsprogs
}

function install_open_jdk7_devel() {
    echo "Installing OpenJDK 7 + devel"
    yum -y install java-1.7.0-openjdk-devel
    echo "export JAVA_HOME=/usr/lib/jvm/java-openjdk" >>/etc/profile.d/java.sh
    echo "export PATH=$JAVA_HOME/bin:\$PATH" >>/etc/profile.d/java.sh
}

function install_ntp() {
    yum -y install ntp
    chkconfig ntpd on
}

function install_unbound() {
    yum -y install unbound
    chkconfig unbound on
    rm -f /etc/unbound/conf.d/example.com.conf
    rm -f /etc/unbound/local.d/block-example.com.conf
}

function install_python27() {
    yum localinstall -y http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm
    rm -f /etc/yum.repos.d/ius-*.repo
    yum install -y python27 python27-setuptools python27-pip
    rm -f /etc/yum.repos.d/ius.repo
}

function install_hdp_dependencies() {
    # the bulk of Ambari install time is taken by these packages and their dependencies
    # since they don't include any actual services, just libraries, they're safe to pre-install
    echo "Pre-installing HDP packages"
    yum install -y mysql-connector-java httpd
    yum_refresh

    # the EPEL repo has a newer version of ganglia that takes precedence over the HDP version
    yum install -y yum-utils
    yum-config-manager --disable epel*
    yum clean all

    yum install -y tez hadoop
    yum_refresh
    yum install -y hive pig
    yum_refresh
    yum install -y oozie falcon
    yum_refresh
    yum install -y spark kafka 
    yum_refresh
    yum install -y storm zookeeper flume
    yum_refresh
    yum install -y ambari-metrics-monitor ambari-metrics-hadoop-sink

    yum -y install python-devel libgfortran openblas-devel lapack-devel python-pip gcc
    # the CentOS version of numpy is too old, surprise
    pip install --upgrade numpy
    pip2.7 install --upgrade numpy

    # some of our custom scripts use ashes templating
    pip install --upgrade ashes
    pip2.7 install --upgrade ashes
}

function ambari_base_image_setup() {
    setup_repos
    fix_requests
    yum_update
    install_xfs_progs
    install_open_jdk7_devel
    install_ntp
    install_unbound
    install_python27
    install_hdp_dependencies
    create_rmstore
}

function create_rmstore() {
    # until https://issues.apache.org/jira/browse/AMBARI-11131 is fixed
    mkdir -p /hadoop/yarn/rmstore
    chown yarn:hadoop /hadoop/yarn/rmstore
}

function install_topo_script() {
    echo "Installing topo.py"
    yum -y install lava-topo
}

function install_hadoop_extras() {
    echo "Installing lzo"
    yum -y install snappy snappy-devel hadoop-lzo lzo lzo-devel hadoop-lzo-native
}

function agent_py26_pin() {
    # python 2.7.9 doesn't work with the ambari agent for now
    echo "PYTHON=/usr/bin/python2.6" >> /var/lib/ambari-agent/ambari-env.sh
}

function postgres_init() {
    echo "Initializing postgresql database"
    service postgresql initdb
    chkconfig postgresql on
}

function install_hdfs_scp() {
    echo "Installing hfds-scp"
    yum install -y hdfs-scp-2.0*
}

function cleanup() {
    rm -f /etc/yum.repos.d/rackspace-cbd.repo
    rm -f /etc/yum.repos.d/hdp.repo
}

echo "Building Ambari Image"
ambari_base_image_setup
install_topo_script
install_hadoop_extras
yum install -y ambari-agent
agent_py26_pin
install_hdfs_scp
cleanup
