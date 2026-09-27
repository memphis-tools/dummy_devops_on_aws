FROM tomcat:latest

# Copy specific directories from webapps.dist to webapps
RUN cp -rap /usr/local/tomcat/webapps.dist/host-manager /usr/local/tomcat/webapps/
RUN cp -rap /usr/local/tomcat/webapps.dist/manager /usr/local/tomcat/webapps/
RUN cp -rap /usr/local/tomcat/webapps.dist/docs /usr/local/tomcat/webapps/
RUN cp -rap /usr/local/tomcat/webapps.dist/examples /usr/local/tomcat/webapps/
RUN cp -rap /usr/local/tomcat/webapps.dist/ROOT /usr/local/tomcat/webapps/
COPY ./*war /usr/local/tomcat/webapps/

RUN mkdir /usr/local/tomcat/secrets
RUN chmod 0750 /usr/local/tomcat/secrets
COPY ./conf/server.xml /usr/local/tomcat/conf/server.xml
COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
COPY ./conf/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml
COPY ./conf/context.xml /usr/local/tomcat/webapps/host-manager/META-INF/context.xml
COPY ./secrets/aws_dummy_ops_docker_tomcat.keystore /usr/local/tomcat/secrets/aws_dummy_ops_docker_tomcat.keystore
RUN chmod 0750 /usr/local/tomcat/secrets/aws_dummy_ops_docker_tomcat.keystore

EXPOSE 8443
EXPOSE 8080
