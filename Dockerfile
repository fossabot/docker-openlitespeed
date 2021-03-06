# Debian 10 base
FROM "bitnami/minideb:buster" 

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="1"
ENV DEBIAN_FRONTEND="noninteractive"

# HTTP port
EXPOSE "80/tcp"

# Webadmin port (HTTPS)
EXPOSE "7080/tcp"

# Install the entrypoint script
COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod "u=rwx,go=" "/entrypoint.sh"

# Make sure we have required tools
RUN install_packages \
	"curl" \
	"gnupg"

# Install the Litespeed keys
RUN curl --silent --show-error \
	"http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg" |\
	apt-key add -

RUN curl --silent --show-error \
	"http://rpms.litespeedtech.com/debian/lst_repo.gpg" |\
	apt-key add -

# Install the Litespeed repository
RUN \
	echo "deb http://rpms.litespeedtech.com/debian/ buster main" > "/etc/apt/sources.list.d/openlitespeed.list"

# Install the Litespeed
RUN install_packages \
	"openlitespeed" && \
	echo "cloud-docker" > "/usr/local/lsws/PLAT"

# Install PageSpeed module
RUN install_packages \
	"ols-pagespeed"

# Install the PHP
RUN install_packages \
	"lsphp74"

# Install PHP modules
RUN install_packages \
	"lsphp74-apcu" \
	"lsphp74-common" \
	"lsphp74-curl" \
	"lsphp74-igbinary" \
	"lsphp74-imagick" \
	"lsphp74-imap" \
	"lsphp74-intl" \
	"lsphp74-json" \
	"lsphp74-ldap" \
	"lsphp74-memcached" \
	"lsphp74-msgpack" \
	"lsphp74-mysql" \
	"lsphp74-opcache" \
	"lsphp74-pear" \
	"lsphp74-pgsql" \
	"lsphp74-pspell" \
	"lsphp74-redis" \
	"lsphp74-sqlite3" \
	"lsphp74-tidy"

# Set the default PHP CLI
RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp74/bin/lsphp" \
	"/usr/local/lsws/fcgi-bin/lsphp5"

RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp74/bin/php7.4" \
	"/usr/bin/php"

# Install the certificates
RUN install_packages \
	"ca-certificates"

# Install requirements
RUN install_packages \
	"procps" \
	"tzdata"

# Create the directories
RUN mkdir --parents \
	"/tmp/lshttpd/gzcache" \
	"/tmp/lshttpd/pagespeed" \
	"/tmp/lshttpd/stats" \
	"/tmp/lshttpd/swap" \
	"/tmp/lshttpd/upload" \
	"/var/log/litespeed"

# Make sure logfiles exist
RUN touch \
	"/var/log/litespeed/server.log" \
	"/var/log/litespeed/access.log"

# Make sure we have access to files
RUN chown --recursive "lsadm:lsadm" \
	"/tmp/lshttpd" \
	"/var/log/litespeed" 

# Configure the admin interface
COPY --chown="lsadm:lsadm" \
	"config/admin_config.conf" \
	"/usr/local/lsws/admin/conf/admin_config.conf"

# Configure the server
COPY --chown="lsadm:lsadm" \
	"config/httpd_config.conf" \
	"/usr/local/lsws/conf/httpd_config.conf"

# Create the virtual host folders
RUN mkdir --parents \
	"/usr/local/lsws/conf/vhosts/container" \
	"/var/www/container" \
	"/var/www/container/web" \
	"/var/www/container/tmp"

# Configure the virtual host
COPY --chown="lsadm:lsadm" \
	"config/vhconf.conf" \
	"/usr/local/lsws/conf/vhosts/container/vhconf.conf"

# Set up the virtual host configuration permissions
RUN chown --recursive "lsadm:lsadm" \
	"/usr/local/lsws/conf/vhosts/container"

# Set up the virtual host document root permissions
RUN chown --recursive "www-data:www-data" \
	"/var/www/container"

RUN chown "www-data:www-data" \
	"/var/www"

# Setup the health checking
HEALTHCHECK \
	--start-period=15s \
	--interval=1m \
	--timeout=3s \
	--retries=3 \
	CMD /usr/local/lsws/bin/lswsctrl 'status' | grep -Ee '^litespeed is running with PID [0-9]+.$'

# Define the volumes used
VOLUME "/tmp/lshttpd" "/var/log/litespeed" "/var/www/container"

# Set the workdir and command
ENV PATH="/usr/local/lsws/bin:${PATH}"
WORKDIR "/var/www/container"
STOPSIGNAL "SIGTERM"
CMD "/entrypoint.sh"
