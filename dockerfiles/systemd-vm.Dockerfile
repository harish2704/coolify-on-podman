FROM debian:12

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update ; \
    apt-get install -y --no-install-recommends \
    systemd systemd-sysv dbus dbus-user-session; \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*; \
    apt-get install -y --no-install-recommends procps iproute2 vim openssh-server;\
    mkdir -p /etc/systemd/system/sshd.service.d; \
    systemctl mask systemd-journald.service systemd-journald.socket; \
    printf "[Unit]\nWants=systemd-user-sessions.service\nAfter=systemd-user-sessions.service\n" > /etc/systemd/system/sshd.service.d/override.conf

EXPOSE 22/tcp

STOPSIGNAL SIGRTMIN+3

ENTRYPOINT [ "/lib/systemd/systemd", "--log-target=console" ]
