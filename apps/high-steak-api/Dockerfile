FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml ./
COPY openapi ./openapi
COPY src ./src
RUN mvn -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
RUN groupadd --system -g 1001 spring && useradd --system -u 1001 -g spring spring
COPY --from=build /app/target/*.jar app.jar
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN mkdir -p /app/uploads \
    && chown -R spring:spring /app \
    && chmod +x /docker-entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/docker-entrypoint.sh"]
