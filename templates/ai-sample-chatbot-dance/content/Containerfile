FROM registry.access.redhat.com/ubi9/python-311:1-77.1726664316
WORKDIR /chat
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir --upgrade -r /chat/requirements.txt
COPY chatbot_ui.py .
EXPOSE 8080
ENV STREAMLIT_SERVER_PORT=8080
ENTRYPOINT [ "streamlit", "run", "chatbot_ui.py" ]
