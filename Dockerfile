# Ansible version 2.7.0 on CentOS7
FROM docker.io/geerlingguy/docker-centos7-ansible

# Install ssh client
RUN yum -y update && yum -y install openssh-clients


RUN pip install --upgrade pip
# setup ec2.py scripts and config
RUN curl https://raw.githubusercontent.com/ansible/ansible/stable-2.7/contrib/inventory/ec2.py -o $HOME_RUNNER/ec2.py \
    && mv $HOME_RUNNER/ec2.py /etc/ansible \
    && curl https://raw.githubusercontent.com/ansible/ansible/stable-2.7/contrib/inventory/ec2.ini -o $HOME_RUNNER/ec2.ini \
    && mv $HOME_RUNNER/ec2.ini /etc/ansible \
    && chmod +x /etc/ansible/ec2.py \
    && pip install boto \
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

# add docker-py
RUN pip install docker-py
# setup Ansible environment variables
ENV ANSIBLE_INVENTORY /etc/ansible/ec2.py
ENV EC2_INI_PATH /etc/ansible/ec2.ini

RUN mkdir /var/ssh
