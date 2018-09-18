# bash_server

## TODO
Every time a command is received a new bash process is create to execute the command, leading to not only performance problem, but also served **stateless**, which means command like *cd* will not work. 

1. Provide stateful service
