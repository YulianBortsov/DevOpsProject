FROM python:3.13.1-slim
WORKDIR /app
COPY ./app.py /app
COPY ./requirements.txt /app
EXPOSE 5000
RUN pip install -r /app/requirements.txt
CMD ["python", "/app/app.py"]