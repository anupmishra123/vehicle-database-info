FROM python:3.6
COPY src /app
RUN apt-get update && \
    python3 -m pip install flask && \
    python3 -m pip install tqdm
WORKDIR /
CMD [ "python", "app/main.py"]


