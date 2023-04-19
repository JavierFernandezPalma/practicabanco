package co.com.bancolombia.config;

import java.io.IOException;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import javax.net.ssl.SSLContext;
import org.apache.http.client.HttpClient;
import org.apache.http.conn.ssl.NoopHostnameVerifier;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.TrustSelfSignedStrategy;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.ssl.SSLContexts;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.ws.transport.http.HttpComponentsMessageSender;
import org.springframework.xml.xsd.SimpleXsdSchema;

import com.consol.citrus.dsl.endpoint.CitrusEndpoints;
import com.consol.citrus.ws.client.WebServiceClient;
import com.consol.citrus.xml.XsdSchemaRepository;

@Configuration
@PropertySource("citrus-application.properties")
public class EndpointConfig {

	@Value("${truststoreSecret}")
	String truststoreSecret;
	@Value("${tramaDummyServiceUrl}")
	String tramaDummyServiceUrl;
	@Value("${recaudosServiceUrl}")
	String recaudosServiceUrl;
	
	@Value("${project.basedir}/src/test/resources/keys/truststore.jks")
    private String sslKeyStorePath;

    
    @Bean
    public SimpleXsdSchema tramaDummySchema() {
        return new SimpleXsdSchema(new ClassPathResource("schemas/tramaDummy.xsd"));
    }

    @Bean
    public XsdSchemaRepository schemaRepository() {
        XsdSchemaRepository schemaRepository = new XsdSchemaRepository();
        schemaRepository.getSchemas().add(tramaDummySchema());
        return schemaRepository;
    }
    
    @Bean
    public WebServiceClient tramaDummyServiceClient() {
    	return CitrusEndpoints.soap()
                            .client()
                            .defaultUri(tramaDummyServiceUrl)
                            .timeout(1000)
                            .build();
    }
    
    @Bean
    public WebServiceClient recaudosServiceClient() {
        return CitrusEndpoints.soap()
                            .client()
                            .defaultUri(recaudosServiceUrl)
                            .messageSender(sslRequestMessageSender())
                            .timeout(1000)
                            .build();
    }
    
    @Bean
    public HttpClient httpClient() {
        try {
            SSLContext sslcontext = SSLContexts.custom()
                    .loadTrustMaterial(new ClassPathResource("keys/truststore.jks").getFile(), "123456".toCharArray(),
                            new TrustSelfSignedStrategy())
                    .build();

            SSLConnectionSocketFactory sslSocketFactory = new SSLConnectionSocketFactory(
                    sslcontext, NoopHostnameVerifier.INSTANCE);

            return HttpClients.custom()
                    .setSSLSocketFactory(sslSocketFactory)
                    .setSSLHostnameVerifier(NoopHostnameVerifier.INSTANCE)
                    .addInterceptorFirst(new HttpComponentsMessageSender.RemoveSoapHeadersInterceptor())
                    .build();
        } catch (IOException | CertificateException | NoSuchAlgorithmException | KeyStoreException | KeyManagementException e) {
            throw new BeanCreationException("Failed to create http client for ssl connection", e);
        }
    }

    @Bean
    public HttpComponentsMessageSender sslRequestMessageSender() {
        return new HttpComponentsMessageSender(httpClient());
    }
    
}