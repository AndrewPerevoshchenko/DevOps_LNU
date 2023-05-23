FROM ubuntu
RUN apt-get update
COPY ./mysqlCheck.sh .
RUN chmod +x ./mysqlCheck.sh
RUN apt-get update && apt-get install -y mysql-client && rm -rf /var/lib/apt
RUN mkdir output && cd /output && touch resultFile.txt && cd ..
EXPOSE 3000
CMD while true; do  *  *  *  *  * sleep 15; ./mysqlCheck.sh; done