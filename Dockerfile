FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    sshpass openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY entrypoint.sh /app/
COPY dpmpv2.py /app/dpmp/
COPY dpmp_fleet.py /app/dpmp/
COPY merge_config.py /app/dpmp/
COPY config_v2_example.json /app/dpmp/
COPY gui_nice/ /app/gui_nice/

WORKDIR /app
RUN chmod +x /app/entrypoint.sh

EXPOSE 3351 8080 9210
CMD ["/app/entrypoint.sh"]
