# docker-crm-erp

various dockerfile and compose for various open source CRM and ERP products
this if for demo purposes only.

included is Dolibarr, x2CRM, vtiger CRM, spiceCRM, vtenext

# why

I could not easily deploy demo single host versions of some of the popular open source CRM solutions out there so I created this repo. Most of the open source CRM solutions originated in sourceforge because of the original parent sugarCRM.

many open source CRM projects are derived from the parent sugarCRM.
this repo consolidates those forks and derivatives in order to demonstrate the differences.
this is by no means a holistic list but we can add more as we discover them.
I am sure there are hundreds of forks out there in the wild. It maybe time to review those in order to improve and build on top of them.

# steps to run

1. clone the repo

`git clone https://github.com/nileio/docker-crm-erp`

2. change directory to the crm folder you wish to use
3. run `docker build` . For example

`docker build -t vtigercrm .`

4. create a new container to run your image. for example

`docker run --name vtigercrm -d -p 80:80 vtigercrm`

the above runs the continaer on port 80

Note: only port 80 is exposed, so it is purely for demo.

All passwords are listed at the top of each Dockerfile. The variables are mostly are :

```
MYSQLROOT_PASSWORD
DBUSER_NAME
DBUSER_PASSWORD
DATABASE_NAME
```

Now you can access and run the setup using http://localhost

# Contributions

very much welcome if you contribute and share Dockerfile or Docker-compose you may have created.

Also as those are pretty simple Dockerfile examples, suggest improvements or report issues.
