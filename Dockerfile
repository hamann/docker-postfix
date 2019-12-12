FROM tozd/runit:ubuntu-xenial

EXPOSE 25/tcp 465/tcp 587/tcp

VOLUME /var/log/postfix
VOLUME /var/spool/postfix

ENV MAILNAME mail.example.com
ENV MY_NETWORKS 172.17.0.0/16 127.0.0.0/8
ENV MY_DESTINATION localhost.localdomain, localhost
ENV ROOT_ALIAS admin@example.com

# /etc/aliases should be available at postfix installation.
COPY ./etc/aliases /etc/aliases

# We disable IPv6 for now, IPv6 is available in Docker even if the host does not have IPv6 connectivity.
RUN apt-get update -q -q && \
 echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections && \
 echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections && \
 echo postfix postfix/mailname string temporary.example.com | debconf-set-selections && \
 apt-get --yes --force-yes install postfix && \
 postconf -e mydestination="localhost.localdomain, localhost" && \
 postconf -e smtpd_banner='$myhostname ESMTP $mail_name' && \
 postconf -# myhostname && \
 postconf -e inet_protocols=ipv4 && \
 postconf -e milter_protocol=2 && \
 postconf -e milter_default_action=accept && \
 postconf -e smtpd_milters=inet:opendkim:12301 && \
 postconf -e non_smtpd_milters=inet:opendkim:12301 && \
 postconf -e smtp_destination_concurrency_limit=2 && \
 postconf -e smtp_destination_rate_delay=2s && \
 postconf -e queue_run_delay=1h && \
 postconf -e minimal_backoff_time=1h && \
 postconf -e maximal_backoff_time=4h && \
 apt-get --yes --force-yes --no-install-recommends install busybox-syslogd

COPY ./etc /etc
