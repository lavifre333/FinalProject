
FROM python:3

ENV DJANGO_SUPERUSER_EMAIL=test@test.com
ENV DJANGO_SUPERUSER_PASSWORD=testpass1234

WORKDIR /opt/status-page

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN bash ./upgrade.sh && python -m venv /opt/status-page/venv && python ./statuspage/manage.py createsuperuser --no-input --username status-page-user

CMD [ "python", "./statuspage/manage.py", "runserver", "0.0.0.0:80", "--insecure"]