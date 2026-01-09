# Employ the standard Ubuntu 24.04 image as the foundation
FROM ubuntu:24.04

# Refresh package lists and set up Python 3 along with pip
RUN apt update -y && \
    apt install -y python3-pip && \
    apt-get clean && \
    mkdir /flask && \
    chmod 777 /flask

COPY main.py /flask/
COPY requirements.txt /flask/
COPY start_payment_flask_app.sh /flask/

RUN sed -i 's/\r$//' /flask/start_payment_flask_app.sh && \
    chmod +x /flask/start_payment_flask_app.sh && \
    pip3 install -r /flask/requirements.txt --break-system-packages

EXPOSE 8000
ENTRYPOINT [ "/flask/start_payment_flask_app.sh" ]