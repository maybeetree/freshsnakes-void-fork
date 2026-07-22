FROM ghcr.io/void-linux/void-glibc-full
RUN \
	xbps-install -Syu xbps && \
	xbps-install -yu && \
	xbps-install -y sudo bash grep curl git && \
	:

