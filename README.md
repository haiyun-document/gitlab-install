### gitlab-install
==============

gitlab-install


### Pre-Install
===========

    # if use debian-minimal install used base tools
    apt-get install curl git sudo

    # fetch the install scripts
    git clone https://github.com/ruedigerp/gitlab-install.git gitlab-install


### Configuration
=============    

    cd gitlab-install 
    vim install.conf

###### MYSQL=0|1 
  * 0 do not install mysql-server and use existing server
  * 1 Install mysql-server 

###### MYSQL_PASS
  * your mysql root password. Not the gitlab mysql password. 

###### MYSQL_GITLAB_PASS
  * password from the gitlab mysql user.

###### OVERRIDE_DEFAULT=0|1
   * 0 do not overrides the default config and use NGINX_VHOSTFILE as filename 
   * 1 overrides the default /etc/nginx/sites-enabled/default 

###### NGINX_VHOSTFILE=filename

   * NGINX_VHOSTFILE=filename


### Intallation


    bash install.sh 

or

    bash install.sh auto
    





