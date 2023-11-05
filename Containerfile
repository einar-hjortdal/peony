FROM docker.io/eurolinux/eurolinux-9:latest

RUN dnf install git make gcc libatomic mysql mysql-devel pkgconf-pkg-config --assumeyes

RUN cd / && git clone https://github.com/vlang/v && cd v && make && ln -s /v/v /usr/bin

COPY . /peony

RUN cd /peony/src && v install

CMD cd /peony && v -cflags "-I/usr/include/mysql" run .

EXPOSE 29000
