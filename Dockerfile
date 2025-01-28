FROM debian:stable-slim AS buildstage

LABEL stage="builder"

RUN groupadd -g 1234 customgroup && useradd -m -d /home/customuser -u 1234 -g customgroup -s /bin/bash customuser

RUN apt-get update && apt-get install -y --no-install-recommends \
  apt-transport-https \
  lsb-release \
  ca-certificates \
  wget && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

WORKDIR /app

RUN wget https://download.moodle.org/download.php/direct/stable405/moodle-latest-405.tgz && tar -xvzf moodle-latest-405.tgz
 
COPY --chmod=750 ./bash-files/change-permission-moodle.sh .

RUN ./change-permission-moodle.sh && rm -f ./moodle-latest-405.tgz



FROM debian:stable-slim

LABEL maintainer="Jayron Castro<jayroncastro@gmail.com>"
LABEL description="Container to run the Moodle 4.5.1 virtual environment using debian bookworm."

RUN groupadd -g 1234 customgroup && useradd -m -d /home/customuser -u 1234 -g customgroup -s /bin/bash customuser

RUN apt-get update && apt-get install -y --no-install-recommends \
  apt-transport-https \
  lsb-release \
  ca-certificates \
  wget && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' && apt-get update && apt-get install -y --no-install-recommends \
  cron \
  apache2 \
  apache2-doc- \
  perl-doc- \
  libapache2-mod-php8.2 \
  php8.2-bcmath \
  php8.2-curl \
  php8.2-gd \
  php8.2-intl \
  php8.2-mbstring \
  php8.2-mysql \
  php8.2-soap \
  php8.2-xml \
  php8.2-xmlrpc \
  php8.2-xsl \
  php8.2-zip && apt-get --purge autoremove -y wget lsb-release apt-transport-https ca-certificates && apt-get clean && apt-get autoclean && apt-get --purge autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && rm -rf /var/www/html && ln -s /home/customuser/moodle /var/www/html

COPY ./config-files/apache2.conf /etc/apache2/
COPY ./config-files/security.conf /etc/apache2/conf-available/
COPY ./config-files/php.ini /etc/php/8.2/apache2/


WORKDIR /home/customuser/moodle

RUN mkdir -p /home/customuser/moodledata && chmod -R 770 /home/customuser && chown -R customuser:customgroup /home/customuser

COPY --from=buildstage /app/moodle .

RUN chown -R root:customgroup /var/log/apache2 && chmod -R 770 /var/log/apache2 && chown -R root:customgroup /var/run/apache2 && chmod -R 770 /var/run/apache2

EXPOSE 80 443

USER customuser

ENTRYPOINT ["apachectl"]
CMD ["-DFOREGROUND"]