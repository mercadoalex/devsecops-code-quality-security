# Tiny deliberately-vulnerable demo app for the DevSecOps course.
# Built into the devsecops-base image cache as two tags:
#   vuln-app:latest   (APP_MODE=vuln    — SQL-injectable /login)
#   vuln-app:patched  (APP_MODE=patched — parameterized /login)
# Stdlib only; ~no deps beyond the slim Python base.
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
ENV APP_MODE=vuln
ENV PORT=80
EXPOSE 80
CMD ["python", "app.py"]
