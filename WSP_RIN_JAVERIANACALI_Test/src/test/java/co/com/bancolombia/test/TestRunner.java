package co.com.bancolombia.test;

import javax.xml.transform.TransformerException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.testng.annotations.Test;

import com.consol.citrus.actions.AbstractTestAction;
import com.consol.citrus.annotations.CitrusTest;
import com.consol.citrus.context.TestContext;
import com.consol.citrus.dsl.testng.TestNGCitrusTestDesigner;
import com.consol.citrus.ws.client.WebServiceClient;

import co.com.bancolombia.utils.Payload;
import co.com.bancolombia.utils.Utils;

@Configuration
@PropertySource("citrus-application.properties")
public class TestRunner extends TestNGCitrusTestDesigner {

	@Value("${spname}")
	String spname;

	@Value("${bankId}")
	String bankId;

	@Value("${custPayeeId}")
	String custPayeeId;

	@Value("${billId}")
	String billId;

	@Value("${amt}")
	String amt;

	@Value("${spname2}")
	String spname2;

	@Value("${billerNum}")
	String billerNum;

	@Autowired
	private WebServiceClient tramaDummyServiceClient;

	@Autowired
	private WebServiceClient recaudosServiceClient;

	public void createSoapConnection(WebServiceClient client, String operation, 
				String spname, String bankId, String custPayeeId, 
				String billId, String amt, String spname2, String billerNum) {
		Payload payload = new Payload();
		try {
			soap().client(client).send().charset("UTF-8").contentType("text/xml")
					.payload(payload.buildPayload(operation, spname, bankId, custPayeeId, billId, amt, spname2, billerNum));
			soap().client(client).receive().schemaValidation(false).build();

		} catch (TransformerException e1) {
			logger.error("Failed to execute Test: " + e1);
		}

		action(new AbstractTestAction() {

			@Override
			public void doExecute(TestContext testContext) {
				try {
					Utils.processPayload(testContext);
				} catch (Exception e) {
					logger.error("Failed to proccess payload: " + e);
				}
			}
		});
	}

	@Test(groups = { "acceptance" })
	@CitrusTest
	public void acceptanceTest() {
		createSoapConnection(tramaDummyServiceClient, "tramaDummy", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
		createSoapConnection(recaudosServiceClient, "registrarPagoIFX", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
		createSoapConnection(recaudosServiceClient, "consultarFacturaPorNumero", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
		//createSoapConnection(recaudosServiceClient, "consultarFacturaPorNit", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
	}

	@Test(groups = { "negative" })
	@CitrusTest
	public void negativeTest() {
		createSoapConnection(tramaDummyServiceClient, "tramaDummy", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
		createSoapConnection(recaudosServiceClient, "registrarPagoIFX", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
		createSoapConnection(recaudosServiceClient, "consultarFacturaPorNumero", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
		//createSoapConnection(recaudosServiceClient, "consultarFacturaPorNit", spname, bankId, custPayeeId, billId, amt, spname2, billerNum);
	}

}
