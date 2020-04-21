# ansible-aws-ssh

This docker container contain everything to interact with an aws ec2 instance using ansible.

# Usage

AWS credentials should be provided when starting the container. You can achieve this by using environment variables:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

In `docker run` command use the `-e` option.
```
docker run -e "AWS_ACCESS_KEY_ID=YoUrAcCeSsKeY" -e  "AWS_SECRET_ACCESS_KEY=YoUrSeCrEtKeY"
```

Then inside your docker container you can run your playbook.
