package com.highsteak.api.config;

import org.apache.catalina.Context;
import org.apache.catalina.Host;
import org.apache.catalina.Wrapper;
import org.apache.catalina.core.StandardContext;
import org.apache.catalina.startup.Tomcat;
import org.apache.catalina.startup.Tomcat.FixContextListener;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class TomcatRootContextConfig {

    @Bean
    WebServerFactoryCustomizer<TomcatServletWebServerFactory> rootWelcomeContextCustomizer() {
        return factory -> factory.addContextCustomizers(apiContext -> {
            Host host = (Host) apiContext.getParent();
            if (host.findChild("") != null) {
                return;
            }

            Context rootContext = new StandardContext();
            rootContext.setPath("");
            rootContext.setDocBase(System.getProperty("java.io.tmpdir"));
            rootContext.addLifecycleListener(new FixContextListener());

            Wrapper wrapper = Tomcat.addServlet(rootContext, "rootWelcome", new RootWelcomeServlet());
            wrapper.addMapping("/");

            host.addChild(rootContext);
        });
    }
}
