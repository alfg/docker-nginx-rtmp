FROM alpine:3.8
RUN apk update		&& \
	apk add			   \
		openssl		   \
		ca-certificates	   \
		stunnel

ADD stunnel.conf /etc/stunnel/stunnel.conf

EXPOSE 19350

CMD /usr/bin/stunnel
