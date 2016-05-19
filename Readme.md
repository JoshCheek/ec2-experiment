Setup ports
===========

Add an additional rule to allow TCP port 80 through
https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#SecurityGroups:sort=groupId

Forward port 80 to 3000:
https://forums.aws.amazon.com/thread.jspa?threadID=82413

```
$ sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 3000
```



