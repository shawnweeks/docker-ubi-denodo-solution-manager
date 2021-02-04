#!/usr/bin/python2

from entrypoint_helpers import env, gen_cfg, set_props

HOME = env["HOME"]

gen_cfg("SMConfigurationParameters.properties.j2", "{}/conf/solution-manager/SMConfigurationParameters.properties".format(HOME))
gen_cfg("LMConfigurationParameters.properties.j2", "{}/conf/license-manager/LMConfigurationParameters.properties".format(HOME))
gen_cfg("VDBConfiguration.properties.j2", "{}/conf/vdp/VDBConfiguration.properties".format(HOME))
gen_cfg("ConfigurationParameters.properties.j2", "{}/conf/webpanel/ConfigurationParameters.properties".format(HOME))
gen_cfg("tomcat.properties.j2", "{}/resources/apache-tomcat/conf/tomcat.properties".format(HOME))