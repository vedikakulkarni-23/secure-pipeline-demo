FROM python:3.12-slim AS base
WORKDIR /app
ENV PYTHONDONTWRITEBYCODE=1\
    PYTHONUNBUFFERED=1
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS test
COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY . .
RUN pytest -q

FROM base AS final
RUN useradd --create-home --uid 10001 appuser
COPY app.py .
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \ 
CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"]
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
