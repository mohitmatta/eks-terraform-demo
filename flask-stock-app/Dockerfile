# Employ the standard Ubuntu 24.04 image as the foundation
FROM ubuntu:24.04

# Refresh package lists and set up Python 3 along with pip
RUN apt update -y && \                              
    apt install -y python3-pip && \                 
    apt-get clean && \                              
    mkdir /flask && \                               
    chmod 777 /flask                                

# Transfer application files into the container's /flask folder
COPY main.py /flask/                                 
COPY requirements.txt /flask/                       
COPY start_flask_app.sh /flask/                     

# Configure the application setup
RUN sed -i 's/\r$//' /flask/start_flask_app.sh && \
    chmod +x /flask/start_flask_app.sh && \         
    pip3 install -r /flask/requirements.txt --break-system-packages 

# Make port 8000 accessible for the Flask app
EXPOSE 8000                                         

# Define the primary command to launch the Flask application
ENTRYPOINT [ "/flask/start_flask_app.sh" ]          
