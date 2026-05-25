FROM python:3.11-slim

WORKDIR /back-end

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
