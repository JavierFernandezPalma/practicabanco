package co.com.bancolombia.utils;

import java.io.StringWriter;
import java.time.LocalDate;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.Marker;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

@Configuration
@PropertySource("citrus-application.properties")
public class Payload {
	
	String tramaDummyNamespace= "http://TramaDummyRIN/";
	String recaudosNamespace = "http://tempuri.org/";
	
	@Value("${SPName}")
	String spname;
	
	static Logger logger = LoggerFactory.getLogger(Payload.class);
	static Marker marker;
	
	LocalDate localDate = LocalDate.now();

	public String buildPayload(String operation, 
			String spnameValue, String bankIdValue, String custPayeeIdValue, 
			String billIdValue, String amtValue, String spname2Value, String billerNumValue) throws TransformerException {
		try {
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
			DocumentBuilder dBuilder = factory.newDocumentBuilder();
			Document doc = dBuilder.newDocument();
			
			TransformerFactory transfac = TransformerFactory.newInstance();
			transfac.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
			Transformer trans = transfac.newTransformer();
			trans.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
			trans.setOutputProperty(OutputKeys.INDENT, "yes");
			
			StringWriter sw = new StringWriter();
			StreamResult result = new StreamResult(sw);
			
			//Elementos Globales 
			Element  ifx = doc.createElement("IFX");
			Element signonRq = doc.createElement("SignonRq");
			Element clientDt = doc.createElement("ClientDt");
			clientDt.setTextContent(Utils.getCurrentTimestamp().toString());
			signonRq.appendChild(clientDt);
			Element custLangPref = doc.createElement("CustLangPref");
			custLangPref.setTextContent("es-CO");
			signonRq.appendChild(custLangPref);
			Element clientApp = doc.createElement("ClientApp");
			Element org = doc.createElement("Org");
			org.setTextContent("Bancolombia");
			clientApp.appendChild(org);
			Element name = doc.createElement("Name");
			name.setTextContent("RIN");
			clientApp.appendChild(name);
			Element version = doc.createElement("Version");
			version.setTextContent("1.0");
			clientApp.appendChild(version);
			signonRq.appendChild(clientApp);
			ifx.appendChild(signonRq);
			Element rqUID = doc.createElement("RqUID");
			rqUID.setTextContent(Utils.generateUUID());
			Element rqUID2 = doc.createElement("RqUID");
			rqUID.setTextContent(Utils.generateUUID());
			
			if(operation.equalsIgnoreCase("tramaDummy")){
				Element envioTramaDummy = doc.createElementNS(tramaDummyNamespace,"tram:envioTramaDummy");
				Element codigoConvenio = doc.createElement("codigoConvenio");
				codigoConvenio.setTextContent(spnameValue);
				envioTramaDummy.appendChild(codigoConvenio);
								
				DOMSource tramaDummysource = new DOMSource(envioTramaDummy);
				StreamResult tramaDummyResult = new StreamResult(sw);
				trans.transform(tramaDummysource, tramaDummyResult);
			}
			
			else if (operation.equalsIgnoreCase("registrarPagoIFX")){
				Element registrarPagoIFX = doc.createElementNS(recaudosNamespace,"RegistrarPagoIFX");
				Element infoPago = doc.createElement("infoPago");	
				Element paySvcRq = doc.createElement("PaySvcRq");
				paySvcRq.appendChild(rqUID);
				Element msgRqHdr = doc.createElement("MsgRqHdr");
				Element networkTrnInfo = doc.createElement("NetworkTrnInfo");
				Element networkOwner = doc.createElement("NetworkOwner");
				networkOwner.setTextContent("BCO");
				networkTrnInfo.appendChild(networkOwner);
				Element bankId = doc.createElement("BankId");
				bankId.setTextContent(bankIdValue);
				networkTrnInfo.appendChild(bankId);
				msgRqHdr.appendChild(networkTrnInfo);
				Element pointOfServiceData = doc.createElement("PointOfServiceData");
				Element environment = doc.createElement("Environment");
				environment.setTextContent(" ");
				pointOfServiceData.appendChild(environment);
				Element posAgent = doc.createElement("POSAgent");
				Element agentId = doc.createElement("AgentId");
				agentId.setTextContent("000");
				posAgent.appendChild(agentId);
				pointOfServiceData.appendChild(posAgent);
				Element posLocation = doc.createElement("POSLocation");
				posLocation.setTextContent("500");
				pointOfServiceData.appendChild(posLocation);
				msgRqHdr.appendChild(pointOfServiceData);		
				paySvcRq.appendChild(msgRqHdr);
				Element spname = doc.createElement("SPName");
				spname.setTextContent(spnameValue);
				paySvcRq.appendChild(spname);
				Element pmtAddRq = doc.createElement("PmtAddRq");
				pmtAddRq.appendChild(rqUID2);
				Element pmtInfo = doc.createElement("PmtInfo");
				Element curAmt = doc.createElement("CurAmt");
				Element amt = doc.createElement("Amt");
				amt.setTextContent("1");
				curAmt.appendChild(amt);
				Element curCode = doc.createElement("CurCode");
				curCode.setTextContent("E");
				curAmt.appendChild(curCode);
				pmtInfo.appendChild(curAmt);
				Element remitInfo = doc.createElement("RemitInfo");
				Element custPayeeId = doc.createElement("CustPayeeId");
				custPayeeId.setTextContent(custPayeeIdValue);
				remitInfo.appendChild(custPayeeId);
				Element billId = doc.createElement("BillId");
				billId.setTextContent(billIdValue);
				remitInfo.appendChild(billId);
				Element pmtId = doc.createElement("PmtId");
				pmtId.setTextContent("0");
				remitInfo.appendChild(pmtId);
				Element curAmt2 = doc.createElement("CurAmt");
				Element amt2 = doc.createElement("Amt");
				amt2.setTextContent(amtValue);
				curAmt2.appendChild(amt2);
				remitInfo.appendChild(curAmt2);
				pmtInfo.appendChild(remitInfo);
				Element depAcctIdfrom = doc.createElement("DepAcctIdFrom");
				Element acctId = doc.createElement("AcctId");
				acctId.setTextContent(" ");
				depAcctIdfrom.appendChild(acctId);
				Element acctType = doc.createElement("AcctType");
				acctType.setTextContent("Default");
				depAcctIdfrom.appendChild(acctType);
				Element bankId2 = doc.createElement("BankId");
				bankId2.setTextContent(" ");
				depAcctIdfrom.appendChild(bankId2);
				pmtInfo.appendChild(depAcctIdfrom);
				Element prcDt = doc.createElement("PrcDt");
				prcDt.setTextContent(localDate.toString());
				pmtInfo.appendChild(prcDt);
				pmtAddRq.appendChild(pmtInfo);
				paySvcRq.appendChild(pmtAddRq);		
				
				ifx.appendChild(paySvcRq);
				
				StringWriter cdata = new StringWriter();
				StreamResult cdataResult = new StreamResult(cdata);
				DOMSource cdataSource = new DOMSource(ifx);
				trans.transform(cdataSource, cdataResult);
				
				infoPago.appendChild(doc.createCDATASection(cdata.toString()));
				registrarPagoIFX.appendChild(infoPago);
				
				DOMSource registrarPagoIFXSource = new DOMSource(registrarPagoIFX);
				trans.transform(registrarPagoIFXSource, result);
			}
			
			else if (operation.equalsIgnoreCase("consultarFacturasPorNit")){
				Element consultarFacturaPorNit = doc.createElementNS(recaudosNamespace,"tem:ConsultarFacturasPorNit");
				Element nit = doc.createElement("nit");
				
				Element presSvcRq = doc.createElement("PresSvcRq");
				presSvcRq.appendChild(rqUID);
				Element billInqRq = doc.createElement("BillInqRq");
				billInqRq.appendChild(rqUID2);
				Element spname = doc.createElement("SPName");
				spname.setTextContent(spnameValue);
				billInqRq.appendChild(spname);
				Element billerId = doc.createElement("BillerId");
				Element spname2 = doc.createElement("SPName");
				spname2.setTextContent(spname2Value);
				billerId.appendChild(spname2);
				Element billNum = doc.createElement("BillNum");
				billNum.setTextContent(billIdValue);
				billerId.appendChild(billNum);
				presSvcRq.appendChild(billerId);
				presSvcRq.appendChild(billInqRq);
				ifx.appendChild(presSvcRq);
				
				StringWriter cdata = new StringWriter();
				StreamResult cdataResult = new StreamResult(cdata);
				DOMSource cdataSource = new DOMSource(ifx);
				trans.transform(cdataSource, cdataResult);
				
				nit.appendChild(doc.createCDATASection(cdata.toString()));
				consultarFacturaPorNit.appendChild(nit);
				
				DOMSource consultarFacturaPorNitSource = new DOMSource(consultarFacturaPorNit);
				trans.transform(consultarFacturaPorNitSource, result);
				
			}
			
			else if (operation.equalsIgnoreCase("consultarFacturaPorNumero")){
				Element consultarFacturaPorNumero = doc.createElementNS(recaudosNamespace,"tem:ConsultarFacturaPorNumero");
				Element numeroFactura = doc.createElementNS(recaudosNamespace,"tem:numeroFactura");
				Element presSvcRq = doc.createElement("PresSvcRq");
				presSvcRq.appendChild(rqUID);
				Element billInqRq = doc.createElement("BillInqRq");
				billInqRq.appendChild(rqUID2);
				Element spname = doc.createElement("SPName");
				spname.setTextContent(spnameValue);
				billInqRq.appendChild(spname);
				Element billId = doc.createElement("BillId");
				billId.setTextContent(billIdValue);
				presSvcRq.appendChild(billId);
				presSvcRq.appendChild(billInqRq);
				ifx.appendChild(presSvcRq);
				
				StringWriter cdata = new StringWriter();
				StreamResult cdataResult = new StreamResult(cdata);
				DOMSource cdataSource = new DOMSource(ifx);
				trans.transform(cdataSource, cdataResult);
				
				numeroFactura.appendChild(doc.createCDATASection(cdata.toString()));
				consultarFacturaPorNumero.appendChild(numeroFactura);
				
				DOMSource consultarFacturaPorNumeroSource = new DOMSource(consultarFacturaPorNumero);
				trans.transform(consultarFacturaPorNumeroSource, result);
			}
			
			else if (operation.equalsIgnoreCase("consultarFacturaPorNegocio")){
				Element consultarFacturaPorNumero = doc.createElementNS(recaudosNamespace,"tem:ConsultarFacturaPorNegocio");
				Element numeroNegocio = doc.createElementNS(recaudosNamespace,"tem:numeroNegocio");
				Element presSvcRq = doc.createElement("PresSvcRq");
				presSvcRq.appendChild(rqUID);
				Element billInqRq = doc.createElement("BillInqRq");
				billInqRq.appendChild(rqUID2);
				Element spname = doc.createElement("SPName");
				spname.setTextContent(spnameValue);
				billInqRq.appendChild(spname);
				Element billId = doc.createElement("BillId");
				billId.setTextContent(billIdValue);
				presSvcRq.appendChild(billId);
				presSvcRq.appendChild(billInqRq);
				ifx.appendChild(presSvcRq);
				
				StringWriter cdata = new StringWriter();
				StreamResult cdataResult = new StreamResult(cdata);
				DOMSource cdataSource = new DOMSource(ifx);
				trans.transform(cdataSource, cdataResult);
				
				numeroNegocio.appendChild(doc.createCDATASection(cdata.toString()));
				consultarFacturaPorNumero.appendChild(numeroNegocio);
				
				DOMSource consultarFacturaPorNumeroSource = new DOMSource(consultarFacturaPorNumero);
				trans.transform(consultarFacturaPorNumeroSource, result);
			}
			return sw.toString();
		} catch (ParserConfigurationException e) {
			String error = String.format("%s",e);
			logger.error(marker, "message {}", error);
			return "error";
		}

	}

}
