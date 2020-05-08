FROM alpine:3.11

VOLUME /data
VOLUME /config/minidlna

RUN apk --no-cache add minidlna tcpdump \
    && mkdir /run/minidlna \
    && chown -R minidlna:minidlna /run/minidlna 

COPY minidlna.conf /etc/conf.d/

RUN chown -R minidlna:minidlna /etc/conf.d/minidlna.conf 

EXPOSE 8200
EXPOSE 1900/udp

CMD /usr/sbin/minidlnad -u minidlna -P /run/minidlna/minidlna.pid -f /etc/conf.d/minidlna.conf -S