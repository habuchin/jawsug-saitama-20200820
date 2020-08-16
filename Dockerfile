FROM amazonlinux:2
ADD ./scripts /scripts/
ENTRYPOINT ["/scripts/hello_saitama.sh"]
