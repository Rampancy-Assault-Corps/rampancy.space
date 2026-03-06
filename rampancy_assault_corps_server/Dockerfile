ARG FLUTTER_BASE_IMAGE=gcr.io/rampancy-space/rampancy-assault-corps-server-flutter-base:3.41.2

FROM ${FLUTTER_BASE_IMAGE}

WORKDIR /app

COPY rampancy_assault_corps_models/pubspec.* /rampancy_assault_corps_models/
COPY rampancy_assault_corps_server/pubspec.* /app/

RUN flutter pub get

COPY rampancy_assault_corps_models/ /rampancy_assault_corps_models/
COPY rampancy_assault_corps_server/ /app/

EXPOSE 8080

CMD ["dart", "run", "lib/main.dart"]
