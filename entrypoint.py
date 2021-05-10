#!/usr/bin/python3

from entrypoint_helpers import env, gen_cfg, set_props

HOME = env["HOME"]

if "DENODO_USE_EXTERNAL_METADATA" in env and env["DENODO_USE_EXTERNAL_METADATA"].lower() == "true":
    gen_cfg("metadb.properties.j2", "{}/conf/metadb.properties".format(HOME))

gen_cfg("SMAdminConfiguration.properties.j2", "{}/conf/solution-manager-web-tool/SMAdminConfiguration.properties".format(HOME))
gen_cfg("SMConfigurationParameters.properties.j2", "{}/conf/solution-manager/SMConfigurationParameters.properties".format(HOME))
gen_cfg("LMConfigurationParameters.properties.j2", "{}/conf/license-manager/LMConfigurationParameters.properties".format(HOME))
gen_cfg("VDBConfiguration.properties.j2", "{}/conf/vdp/VDBConfiguration.properties".format(HOME))
#gen_cfg("ConfigurationParameters.properties.j2", "{}/resources/apache-tomcat/webapps/solution-manager-web-tool/WEB-INF/classes/ConfigurationParameters.properties".format(HOME))
gen_cfg("tomcat.properties.j2", "{}/resources/apache-tomcat/conf/tomcat.properties".format(HOME))
gen_cfg("server.xml.j2", "{}/resources/apache-tomcat/conf/server.xml".format(HOME))
gen_cfg("ConfigurationParametersGeneral.template.j2", "{}/conf/solution-manager/denodo-monitor/ConfigurationParametersGeneral.template".format(HOME))