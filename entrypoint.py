#!/usr/bin/python3

from entrypoint_helpers import env, gen_cfg

HOME = env["HOME"]

# Setting Logging Format
gen_cfg("license-manager-log4j2.xml.j2", "{}/conf/license-manager/log4j2.xml".format(HOME))
gen_cfg("solution-manager-log4j2.xml.j2", "{}/conf/solution-manager/log4j2.xml".format(HOME))
gen_cfg("db-tools-log4j2.xml.j2", "{}/conf/db-tools/log4j2.xml".format(HOME))
gen_cfg("vdp-log4j2.xml.j2", "{}/conf/vdp/log4j2.xml".format(HOME))
gen_cfg("denodo-sso-log4j2.xml.j2", "{}/resources/apache-tomcat/webapps/sso/WEB-INF/classes/log4j2.xml".format(HOME))
gen_cfg("solution-manager-web-tool-log4j2.xml.j2", "{}/resources/apache-tomcat/webapps/solution-manager-web-tool/WEB-INF/classes/log4j2.xml".format(HOME))
gen_cfg("denodo-design-studio-log4j2.xml.j2", "{}/resources/apache-tomcat/webapps/denodo-design-studio/WEB-INF/classes/log4j2.xml".format(HOME))
gen_cfg("diagnostic-monitoring-tool-log4j2.xml.j2", "{}/resources/apache-tomcat/webapps/diagnostic-monitoring-tool/WEB-INF/classes/log4j2.xml".format(HOME))
gen_cfg("denodo-scheduler-admin-log4j2.xml.j2", "{}/resources/apache-tomcat/webapps/webadmin#denodo-scheduler-admin/WEB-INF/classes/log4j2.xml".format(HOME))
gen_cfg("apache-tomcat-log4j2.xml.j2", "{}/resources/apache-tomcat/lib/log4j2.xml".format(HOME))
gen_cfg("apache-tomcat-logging.properties.j2", "{}/resources/apache-tomcat/conf/logging.properties".format(HOME))