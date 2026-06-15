FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY hyp-service/target/*.jar app.jar

EXPOSE 8080

RUN addgroup -S hyp && adduser -S hyp -G hyp
USER hyp

ENTRYPOINT ["java", "-XX:+UseZGC", "-Xms256m", "-Xmx512m", "-jar", "app.jar"]
