package co.com.bancolombia.utils;

import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.util.Date;
import java.util.Map;
import java.util.Map.Entry;
import java.util.UUID;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.Marker;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import com.consol.citrus.context.TestContext;
import com.consol.citrus.message.DefaultMessageStore;
import com.consol.citrus.message.Message;

public class Utils {

	static Logger logger = LoggerFactory.getLogger(Utils.class);
	static Marker marker;

	private Utils() {

	}

	public static String xmlPrettyPrint(String message) {

		try {
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
			Document doc = factory.newDocumentBuilder().parse(new InputSource(new StringReader(message)));
			TransformerFactory transformerFactory = TransformerFactory.newInstance();
			transformerFactory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
			Transformer transformer = transformerFactory.newTransformer();
			transformer.setOutputProperty(OutputKeys.INDENT, "yes");
			StreamResult result = new StreamResult(new StringWriter());
			DOMSource source = new DOMSource(doc);
			transformer.transform(source, result);
			return result.getWriter().toString();
		} catch (IOException | SAXException | ParserConfigurationException
				| TransformerFactoryConfigurationError | TransformerException e) {
			String error = String.format("%s",e);
			logger.error(marker, "message {}", error);
			return (e.toString());
		}
		
	}

	public static void processPayload(TestContext testContext) {

		Map<String, Message> requestStore = (DefaultMessageStore) testContext.getMessageStore();
		Map<String, Message> responseStore = (DefaultMessageStore) testContext.getMessageStore();

		for (Entry<String, Message> requestEntry : requestStore.entrySet()) {
			if (requestEntry.getKey().contains("send")) {
				Message requestMessage = responseStore.get(requestEntry.getKey());
				String request = requestMessage.getPayload().toString(); 
				logger.info(request);
			}
		}

		for (Entry<String, Message> responseEntry : responseStore.entrySet()) {
			if (responseEntry.getKey().contains("receive")) {
				Message responseMessage = responseStore.get(responseEntry.getKey());
				String response = xmlPrettyPrint(responseMessage.getPayload().toString());
				logger.info(response);
			}
		}
	}
	
	public static String generateUUID(){
		String source = "http://entappfwtx.bancolombia.grporg.com.co";
		byte[] bytes;
		UUID uuid;
		bytes = source.getBytes(StandardCharsets.UTF_8);
		uuid = UUID.nameUUIDFromBytes(bytes);
		return uuid.toString();
		
	}
	
	public static Date getCurrentTimestamp() {
		Date date = new Date();
		return new Timestamp(date.getTime());
	}
	
	
}
