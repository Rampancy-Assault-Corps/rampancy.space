FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git /flutter
RUN git -C /flutter checkout stable
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app

COPY rampancy_assault_corps_models/ /rampancy_assault_corps_models/
COPY rampancy_assault_corps_server/ /app/

RUN flutter pub get

EXPOSE 8080

CMD ["dart", "run", "lib/main.dart"]
