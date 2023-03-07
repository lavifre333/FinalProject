FROM python:3

# install nginx
RUN apt-get update && apt-get install nginx -y 

COPY ./contrib/nginx.conf /etc/nginx/sites-available/status-page.conf
# link nginx logs to container stdout
RUN rm /etc/nginx/sites-enabled/default && \
ln -s /etc/nginx/sites-available/status-page.conf /etc/nginx/sites-enabled/status-page.conf

WORKDIR /opt/status-page

COPY . .

RUN chmod +x entrypoint.sh &&\
    bash ./upgrade.sh

EXPOSE 80

# execute our entrypoint.sh file
CMD ["./entrypoint.sh"]