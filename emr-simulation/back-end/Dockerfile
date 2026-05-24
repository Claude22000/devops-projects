FROM python:3.11-slim

WORKDIR .

COPY . .
RUN pip install -r requirements.txt

CMD ["python", "manage.py"]