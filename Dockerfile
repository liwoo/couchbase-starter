FROM couchbase:enterprise-6.6.1

COPY configure-server.sh /opt/couchbase

CMD ["/opt/couchbase/configure-server.sh"]
