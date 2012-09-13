#!/bin/sh

if [ -e /home/git/.first_installrun.lock ]
then
	echo "Dieses Script ist schon mal gelaufen. /home/git/.first_installrun.lock ist vorhanden. "
	echo "Zum testen ob alles klappt:"
	echo "sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin"
	exit 1; 
fi
export AUTOMODE=$1
source ./install.conf

function presseenter {
	if [ "$AUTOMODE" == "auto" ]
	then 
		echo "automode"
		return
	fi
	echo -n " Ready? Press Enter "
	read X
}
echo -n "Install Base Packages."; presseenter
apt-get install -y git git-core wget curl gcc checkinstall libxml2-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server python-dev python-pip libyaml-dev postfix

echo -n "Install nginx Server"; presseenter
apt-get install -y nginx

echo -n "Install Mysql Database" ; presseenter
if [ "$MYSQL" eq 1 ]
then
apt-get install -y mysql-server mysql-client libmysqlclient-dev
fi

echo "Datenbank anlegen und datenbankuser einrichten."
echo "CREATE DATABASE IF NOT EXISTS \`gitlabhq_production\` DEFAULT CHARACTER SET \`utf8\` COLLATE \`utf8_unicode_ci\`;" > ./gitlab_db.sql
echo "CREATE USER 'gitlab'@'$MYSQL_HOST' IDENTIFIED BY '$MYSQL_GITLAB_PASS';" >> ./gitlab_db.sql
echo "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON \`gitlabhq_production\`.* TO 'gitlab'@'$MYSQL_HOST';" >> ./gitlab_db.sql
echo "Import der mysql user daten" 
mysql -h $MYSQL_HOST -u root -p$MYSQL_PASS < /root/gitlab_db.sql

echo -n "Install ruby 1.9.3"; pressenter
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
tar xfvz ruby-1.9.3-p194.tar.gz
cd ruby-1.9.3-p194
./configure
make
sudo make install

echo -n "Add user git and gitlab"; pressenter
sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'git version control' \
  --group \
  --disabled-password \
  --home /home/git \
  git

sudo adduser --disabled-login --gecos 'gitlab system' gitlab

sudo usermod -a -G git gitlab

echo -n "generate SSH-Key"; pressenter
sudo -H -u gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

echo -n "Git clone gitolite"; pressenter
cd /home/git
sudo -H -u git git clone http://github.com/gitlabhq/gitolite /home/git/gitolite

echo -n "Install gitolite, config and add ssh key"; pressenter
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; /home/git/gitolite/src/gl-system-install"
sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
sudo chmod 777 /home/git/gitlab.pub

sudo -u git -H sed -i 's/0077/0007/g' /home/git/share/gitolite/conf/example.gitolite.rc
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gl-setup -q /home/git/gitlab.pub"

echo -n "Create repository direkctory"; pressenter 
mkdir /home/git/repositories/
sudo chmod -R g+rww /home/git/repositories/
sudo chown -R git:git /home/git/repositories/

echo -n "Install gitolite-admin"; pressenter
sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

echo -n "Install gem package charlock_holmes"; pressenter
sudo gem install charlock_holmes --version '0.6.8'

echo -n  "Install pip package pygments"; pressenter
sudo pip install pygments
echo -n "Install gem package bundler"; pressenter 
sudo gem install bundler

echo -n "Install gitlabhq"
cd /home/gitlab
sudo -H -u gitlab git clone -b stable http://github.com/gitlabhq/gitlabhq.git gitlab

echo -n "Create some directories, configs and edit some files"; pressenter
cd gitlab
sudo -u gitlab mkdir tmp
sudo -u gitlab cp config/gitlab.yml.example config/gitlab.yml
sudo -u gitlab cp config/database.yml.example config/database.yml
sed -i 's/root/gitlab/' config/database.yml
sed -i s/secure password/$MYSQL_GITLAB_PASS/ config/database.yml

echo -n "Install gem Package json"; pressenter
gem install json -v '1.7.4'
echo -n "Install gem Package carrierwave"; pressenter
gem install carrierwave

echo -n "Bundle install for gitlab"; pressenter
cd /home/gitlab/gitlab
sudo -u gitlab bundle install
sudo -u gitlab -H bundle install --without development test --deployment

echo -n "Bundle exec"; pressenter
sudo -u gitlab bundle exec rake gitlab:app:setup RAILS_ENV=production

echo -n "Copy post-receive"; pressenter
sudo cp ./lib/hooks/post-receive /home/git/share/gitolite/hooks/common/post-receive
echo -n "Fix permissions"; pressenter
sudo chown git:git /home/git/share/gitolite/hooks/common/post-receive
echo -n "Bundle status"; pressenter
sudo -u gitlab bundle exec rake gitlab:app:status RAILS_ENV=production

echo -n "Setup unicorn for webserver"; pressenter
cd /home/gitlab/gitlab
sudo -u gitlab cp config/unicorn.rb.orig config/unicorn.rb
sudo -u gitlab bundle exec unicorn_rails -c config/unicorn.rb -E production -D

echo -n "Set permission on repositories"; pressenter
chmod -R g+rwx /home/git/repositories/
chown -R git:git /home/git/repositories/

echo -n "Install nginx vhost config"; pressenter
curl -s -o ./nginx-default https://raw.github.com/ruedigerp/gitlab-install/master/nginx-default
if [ "$OVERRIDE_DEFAULT" eq 1 ]
then
	cp -av ./nginx-default /etc/nginx/sites-enabled/default
else 
	cp -av ./nginx-default /etc/nginx/sites-enabled/$gitlab
fi
/etc/init.d/nginx restart

touch /home/git/.first_installrun.lock


