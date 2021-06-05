Dockerfile and Docker-compose for vtiger-crm

# vtiger-crm

A simple Dockerfile to install vtigercrm community edition for demo purposes. You can change the required version and used credentials using environment variables.
The Dockerfile build includes apache, php and mysql on the same ubuntu host, so use this for demo purposes only.

# Launching on railway.app

[DOES NOT WORK atm require a fix - please build image yourself as below]

[Railway](https://railway.app) is a new cloud development platform! ☁️

One-click deploy of vtiger server that you can access from any device.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new?template=https%3A%2F%2Fgithub.com%2Fnileio%2Fdocker-crm-erp&envs=PORT&PORTDefault=80)

# How to use

If you want to build the image yourself, first clone the repo.

```
git clone https://github.com/nileio/docker-crm-erp
```

then inside the vtiger-crm directory run

```
docker build -t vtigercrm .
```

Now, you can create a container from the image.

to run a continer with the default credentials use:

```
docker run -d -p 80:80 vtigercrm
```

if you want to change environment variables you can either use an
env_file or pass the env vars to the `docker run` command. All default values for environment variables are listed in the file env_vtigercrm.

example for passing env vars:

```
docker run -d -e "MYSQL_ROOT_PASSWORD=MyPassword" -p 80:80 vtigercrm
```

example using an env_file

First, create an env_file in the same directory. example env_file is included in the repo.
Then you can run

```
docker run -d --env-file=env_file_name -p 80:80 vtigercrm
```

You can then access vtiger using http://localhost:80 and follow the wizard to complete the setup.

Host name should be `localhost`
The default database user is `vtigeradm` and password is `myStr0nGp@ss`, and default database name is `vtiger`

Please star or leave a comment for me!
