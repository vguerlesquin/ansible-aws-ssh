FROM centos:8
LABEL maintainer="Valentin Guerlesquin"
ENV container=docker

# Install what we need
RUN yum -y -q --nogpgcheck update
RUN yum -y -q --nogpgcheck install sudo which python3-pip openssh-clients
RUN yum clean all

RUN ln -s /usr/bin/pip3 /usr/bin/pip
RUN pip install -q --upgrade pip

# Install Ansible, boto, docker-py via Pip.
RUN pip install ansible boto docker-py

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# setup ec2.py scripts and config
RUN curl -s https://raw.githubusercontent.com/ansible/ansible/stable-2.7/contrib/inventory/ec2.py -o $HOME_RUNNER/ec2.py \
    && mv $HOME_RUNNER/ec2.py /etc/ansible \
    && curl -s https://raw.githubusercontent.com/ansible/ansible/stable-2.7/contrib/inventory/ec2.ini -o $HOME_RUNNER/ec2.ini \
    && mv $HOME_RUNNER/ec2.ini /etc/ansible \
    && chmod +x /etc/ansible/ec2.py \
    && sed -i '/destination_variable = /s/public_dns_name/private_dns_name/g' /etc/ansible/ec2.ini \
    && sed -i '/vpc_destination_variable = /s/ip_address/private_ip_address/g' /etc/ansible/ec2.ini

# create and modify ansible.cfg file to use AWS dynamic inventory as default
RUN touch /etc/ansible/ansible.cfg
RUN echo $'[defaults] \n\
inventory = /etc/ansible/ec2.py \n\
transport = ssh \n\
host_key_checking = False \n\
\n\
[ssh_connection]\n\
ssh_args = \n\
scp_if_ssh = True \n' >> /etc/ansible/ansible.cfg

# setup Ansible environment variables
ENV ANSIBLE_INVENTORY /etc/ansible/ec2.py
ENV EC2_INI_PATH /etc/ansible/ec2.ini

RUN mkdir /var/ssh

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/lib/systemd/systemd"]
