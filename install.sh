#!/bin/sh

if [ -e /home/git/.first_installrun.lock ]
then
	echo "Dieses Script ist schon mal gelaufen. /home/git/.first_installrun.lock ist vorhanden. "
	echo "Zum testen ob alles klappt:"
	echo "sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin"
	exit 1; 
fi
cd /home/git

apt-get install -y git git-core wget curl gcc checkinstall libxml2-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server python-dev python-pip libyaml-dev postfix

apt-get install -y nginx
apt-get install -y mysql-server mysql-client libmysqlclient-dev

wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
tar xfvz ruby-1.9.3-p194.tar.gz
cd ruby-1.9.3-p194
./configure
make
sudo make install

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

sudo -H -u gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

cd /home/git
sudo -H -u git git clone http://github.com/gitlabhq/gitolite /home/git/gitolite

sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; /home/git/gitolite/src/gl-system-install"
sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
sudo chmod 777 /home/git/gitlab.pub

sudo -u git -H sed -i 's/0077/0007/g' /home/git/share/gitolite/conf/example.gitolite.rc
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gl-setup -q /home/git/gitlab.pub"

sudo chmod -R g+rwX /home/git/repositories/
sudo chown -R git:git /home/git/repositories/

sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

sudo gem install charlock_holmes --version '0.6.8'

echo "pip install pygments"
sudo pip install pygments
echo "gem install bundler"
sudo gem install bundler
cd /home/gitlab
sudo -H -u gitlab git clone -b stable http://github.com/gitlabhq/gitlabhq.git gitlab
cd gitlab
sudo -u gitlab mkdir tmp
sudo -u gitlab cp config/gitlab.yml.example config/gitlab.yml
echo "CREATE DATABASE IF NOT EXISTS \`gitlabhq_production\` DEFAULT CHARACTER SET \`utf8\` COLLATE \`utf8_unicode_ci\`;" > /root/gitlab_db.sql
echo "CREATE USER 'gitlab'@'localhost' IDENTIFIED BY 'newpassword';" >> /root/gitlab_db.sql
echo "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON \`gitlabhq_production\`.* TO 'gitlab'@'localhost';" >> /root/gitlab_db.sql
echo "Import der mysql user daten" 
mysql -u root -p < /root/gitlab_db.sql
sudo -u gitlab cp config/database.yml.example config/database.yml
sed -i 's/root/gitlab/' config/database.yml
sed -i 's/secure password/newpassword/' config/database.yml

gem install json -v '1.7.4'
gem install carrierwave

cd /home/gitlab/gitlab

sudo -u gitlab bundle install

echo "bundle install "
sudo -u gitlab -H bundle install --without development test --deployment

echo "bundle exec"
sudo -u gitlab bundle exec rake gitlab:app:setup RAILS_ENV=production

echo "copy post-receive"
sudo cp ./lib/hooks/post-receive /home/git/share/gitolite/hooks/common/post-receive
echo "Fix permissions"
sudo chown git:git /home/git/share/gitolite/hooks/common/post-receive
echo "bundle status"
sudo -u gitlab bundle exec rake gitlab:app:status RAILS_ENV=production

cd /home/gitlab/gitlab
sudo -u gitlab cp config/unicorn.rb.orig config/unicorn.rb
sudo -u gitlab bundle exec unicorn_rails -c config/unicorn.rb -E production -D

mkdir /home/git/repositories/

chmod -R g+rwx /home/git/repositories/
chown -R git:git /home/git/repositories/

curl -s -o /tmp/nginx-default https://github.com/ruedigerp/gitlab-install/blob/master/nginx-default
cp -av /tmp/nginx-default /etc/nginx/sites-enabled/

touch /home/git/.first_installrun.lock


