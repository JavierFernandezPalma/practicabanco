<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:date="http://exslt.org/dates-and-times"
                xmlns:vcsoft="http://vc-soft.com/vcsoft/functions"
                extension-element-prefixes="dp vcsoft date"
                exclude-result-prefixes="dp vcsoft date">
    <!-- Se incluyen los XSL requeridos -->
    <xsl:include href="local:///CashManagement/xsl/utils_rin.xsl"/>
    <xsl:include href="local:///CashManagement/xsl/messaging_handling.xsl"/>
    <xsl:include href="local:///common/equivalence_manager/xsl/equivalence_manager.xsl"/>
    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:template match="/">
        <!-- Se consulta el tipo de Log -->
        <xsl:variable name="processorName" select="dp:variable('var://service/processor-name')"/>
        <!-- Extraccion del Mensaje Body-->
        <xsl:variable name="soapBody" select="*[local-name()='Envelope']/*[local-name()='Body']/*[1]"/>
        <!-- Extraccion del Mensaje Body-->
        <xsl:variable name="method" select="local-name($soapBody)"/>
        <dp:set-variable name="'var://context/store/method'" value="$method"/>
        <!-- Id de la transaccion en DataPower-->
        <xsl:variable name="transaccionId" select="dp:variable('var://service/transaction-id')"/>
        <!-- Id del Convenio-->
        <xsl:variable name="convenio" select="dp:variable('var://context/transaction/convenio')"/>
        <!--Flag para aplicar politica soapUserNamePassword -->
        <xsl:variable name="soapUserNamePasswordFlag" select="dp:variable('var://context/transaction/soapUserNamePassword')"/>
        <!-- Log/Request | WAS RIN > RIN Standard -->
        <xsl:call-template name="registerLog">
            <xsl:with-param name="logType" select="$LOG_TYPE_REQUEST_IN"/>
            <xsl:with-param name="processorName" select="$processorName"/>
            <xsl:with-param name="transaccionId" select="$transaccionId"/>
            <xsl:with-param name="convenio" select="$convenio"/>
            <xsl:with-param name="transactionMethod" select="$method"/>
            <xsl:with-param name="message" select="$soapBody"/>
        </xsl:call-template>
        <xsl:variable name="srtIFXParam">
            <xsl:call-template name="cDataToString">
                <xsl:with-param name="cData" select="string($soapBody/*[1])" />
            </xsl:call-template>
        </xsl:variable>
        <!-- Se convierte seccion IFX a Nodeset para poder extraer los datos-->
        <xsl:variable name="srtIFX" select="dp:parse($srtIFXParam)" />
        <dp:set-variable name="'var://context/store/srtIFX'" value="$srtIFX"/>
        <!-- Variables Globales-->
        <xsl:variable name="clientDt" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientDt']"/>
        <xsl:variable name="custLangPref" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='CustLangPref']"/>
        <xsl:variable name="org" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Org']"/>
        <xsl:variable name="name" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Name']"/>
        <xsl:variable name="version" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Version']"/>
        <xsl:variable name="rquid" select="$srtIFX/*[local-name()='IFX']/*[2]/*[local-name()='RqUID']"/>
        <!-- Username y Password -->
        <xsl:variable name="username" select="dp:variable('var://context/transaction/wsseUsername')"/>
        <xsl:variable name="password" select="vcsoft:decryptPassword(dp:variable('var://context/transaction/wssePassword'))"/>
        <xsl:variable name="soapMessage">
            <soap:Envelope xmlns:tem="http://tempuri.org/"
                           xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
                <xsl:choose>
                    <xsl:when test="$method='VerificarEstadoWebService'">
                        <!-- Incluir en el atributo value el valor correspondientee para esta operacion -->
                        <dp:set-http-request-header name="'Content-type'" value="concat('application/soap+xml;charset=UTF-8;action=&quot;http://tempuri.org/IWCFPagoVentanilla/VerificarEstadoWebServiceGen&quot;')"/>
                        <dp:freeze-headers/>
                        <!-- Mapeo del Body para la trama dummy -->
                        <soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">
                            <wsa:Action>http://tempuri.org/IWCFPagoVentanilla/VerificarEstadoWebServiceGen</wsa:Action>
                            <wsa:To>https://172.25.59.4:59511/WCFPagoVentanillaProxySign/WCFPagoVentanilla.svc</wsa:To>
                        </soap:Header>
                        <soap:Body>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRq>
                                        <ClientDt>
                                            <xsl:value-of select="$clientDt"/>
                                        </ClientDt>
                                        <CustLangPref>es-CO</CustLangPref>
                                        <ClientApp>
                                            <Org>Bancolombia</Org>
                                            <Name>App</Name>
                                            <Version>1.0</Version>
                                        </ClientApp>
                                    </SignonRq>
                                </IFX>
                            </xsl:variable>
                            <tem:VerificarEstadoWebServiceGen>
                                <!--Optional:-->
                                <tem:infoDummy>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/> 
                                </tem:infoDummy>
                                <!--Optional:-->
                                <tem:codigoBanco>7</tem:codigoBanco>
                            </tem:VerificarEstadoWebServiceGen>
                        </soap:Body>
                    </xsl:when>
                    <xsl:when test="$method='ConsultarFacturaPorNumero'">
                        <!-- Incluir en el atributo value el valor correspondiente para esta operacion -->
                        <dp:set-http-request-header name="'Content-type'" value="concat('application/soap+xml;charset=UTF-8;action=&quot;http://tempuri.org/IWCFPagoVentanilla/ConsultarCuponesGen&quot;')"/>
                        <dp:freeze-headers/>
                        <!--Variables para la construccion del mensaje Request-->
                        <xsl:variable name="sPNameConsulta" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='SPName']"/>
                        <xsl:variable name="billIdConsulta" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='BillId']"/>
                        <xsl:variable name="rqUIDConsulta" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='RqUID']"/>   
                        <xsl:variable name="custLangPref" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='CustLangPref']"/>
                        <xsl:variable name="org" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Org']"/>
                        <xsl:variable name="name" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Name']"/>
                        <xsl:variable name="version" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Version']"/>
                        <xsl:variable name="billInqRqRqUID" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='RqUID']"/>
                        <!-- Mapeo del Body para consultar facturas por numero -->
                        <soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">
                            <wsa:Action>http://tempuri.org/IWCFPagoVentanilla/ConsultarCuponesGen</wsa:Action>
                            <wsa:To>https://172.25.59.4:59511/WCFPagoVentanillaProxySign/WCFPagoVentanilla.svc</wsa:To>
                        </soap:Header>
                        <soap:Body>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRq>
                                        <ClientDt>
                                            <xsl:value-of select="$clientDt"/>
                                        </ClientDt>
                                        <CustLangPref>
                                            <xsl:value-of select="$custLangPref"/>
                                        </CustLangPref>
                                        <ClientApp>
                                            <Org>
                                                <xsl:value-of select="$org"/>
                                            </Org>
                                            <Name>
                                                <xsl:value-of select="$name"/>
                                            </Name>
                                            <Version>
                                                <xsl:value-of select="$version"/>
                                            </Version>
                                        </ClientApp>
                                    </SignonRq>
                                    <PresSvcRq>
                                        <RqUID>
                                            <xsl:value-of select="$rqUIDConsulta"/>
                                        </RqUID>
                                        <MsgRqHdr>
                                            <NetworkTrnInfo>
                                                <NetworkOwner>2</NetworkOwner>
                                                <BankId>7</BankId>
                                            </NetworkTrnInfo>
                                            <PointOfServiceData>
                                                <Environment/>
                                                <POSAgent>
                                                    <AgentId>0000</AgentId>
                                                </POSAgent>
                                                <POSLocation>0000</POSLocation>
                                            </PointOfServiceData>
                                        </MsgRqHdr>
                                        <BillInqRq>
                                            <RqUID>
                                                <xsl:value-of select="$billInqRqRqUID"/>
                                            </RqUID>
                                            <SPName>100</SPName>
                                            <BillerId>
                                                <BillerNum>
                                                    <xsl:value-of select="format-number(translate($billIdConsulta,'-',''), '#')"/>
                                                </BillerNum>
                                            </BillerId>
                                        </BillInqRq>
                                    </PresSvcRq>
                                </IFX>
                            </xsl:variable>
                            <tem:ConsultarCuponesGen>
                                <!--Optional:-->
                                <tem:infoConsulta>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/> 
                                </tem:infoConsulta>
                                <!--Optional:-->
                                <tem:codigoBanco>7</tem:codigoBanco>
                                <!--Optional:-->
                                <tem:tipoDocumento>1</tem:tipoDocumento>
                            </tem:ConsultarCuponesGen>
                        </soap:Body>
                    </xsl:when>
                    <!-- Si el metodo es ConsultarFacturasPorNegocio se construye mensaje de respuesta -->
                    <xsl:when test="$method='ConsultarFacturasPorNegocio'">
                        <!-- Incluir en el atributo value el valor correspondiente para esta operacion -->
                        <dp:set-http-request-header name="'Content-type'" value="concat('application/soap+xml;charset=UTF-8;action=&quot;http://tempuri.org/IWCFPagoVentanilla/ConsultarCuponesGen&quot;')"/>
                        <dp:freeze-headers/>
                        <!--Variables para la construccion del mensaje Request-->
                        <xsl:variable name="sPNameNegocio" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='SPName']"/>
                        <xsl:variable name="billerNumNegocio" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='BillerId']/*[local-name()='BillerNum']"/>
                        <xsl:variable name="sPNameConsulta" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='SPName']"/>
                        <xsl:variable name="billIdConsulta" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='BillId']"/>
                        <xsl:variable name="rqUIDNegocio" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='RqUID']"/>   
                        <xsl:variable name="custLangPref" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='CustLangPref']"/>
                        <xsl:variable name="org" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Org']"/>
                        <xsl:variable name="name" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Name']"/>
                        <xsl:variable name="version" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Version']"/>
                        <xsl:variable name="billInqRqRqUID" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='RqUID']"/>
                        <!-- Mapeo del Body para consultar facturas por numero -->
                        <soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">
                            <wsa:Action>http://tempuri.org/IWCFPagoVentanilla/ConsultarCuponesGen</wsa:Action>
                            <wsa:To>https://172.25.59.4:59511/WCFPagoVentanillaProxySign/WCFPagoVentanilla.svc</wsa:To>
                        </soap:Header>
                        <soap:Body>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRq>
                                        <ClientDt>
                                            <xsl:value-of select="$clientDt"/>
                                        </ClientDt>
                                        <CustLangPref>
                                            <xsl:value-of select="$custLangPref"/>
                                        </CustLangPref>
                                        <ClientApp>
                                            <Org>
                                                <xsl:value-of select="$org"/>
                                            </Org>
                                            <Name>
                                                <xsl:value-of select="$name"/>
                                            </Name>
                                            <Version>
                                                <xsl:value-of select="$version"/>
                                            </Version>
                                        </ClientApp>
                                    </SignonRq>
                                    <PresSvcRq>
                                        <RqUID>
                                            <xsl:value-of select="$rqUIDNegocio"/>
                                        </RqUID>
                                        <MsgRqHdr>
                                            <NetworkTrnInfo>
                                                <NetworkOwner>2</NetworkOwner>
                                                <BankId>7</BankId>
                                            </NetworkTrnInfo>
                                            <PointOfServiceData>
                                                <Environment/>
                                                <POSAgent>
                                                    <AgentId>0000</AgentId>
                                                </POSAgent>
                                                <POSLocation>0000</POSLocation>
                                            </PointOfServiceData>
                                        </MsgRqHdr>
                                        <BillInqRq>
                                            <RqUID>
                                                <xsl:value-of select="$billInqRqRqUID"/>
                                            </RqUID>
                                            <SPName>100</SPName>
                                            <BillerId>
                                                <BillerNum>
                                                    <xsl:value-of select="$billerNumNegocio"/>
                                                </BillerNum>
                                            </BillerId>
                                        </BillInqRq>
                                    </PresSvcRq>
                                </IFX>
                            </xsl:variable>
                            <tem:ConsultarCuponesGen>
                                <!--Optional:-->
                                <tem:infoConsulta>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/> 
                                </tem:infoConsulta>
                                <!--Optional:-->
                                <tem:codigoBanco>7</tem:codigoBanco>
                                <!--Optional:-->
                                <tem:tipoDocumento>0</tem:tipoDocumento>
                            </tem:ConsultarCuponesGen>
                        </soap:Body>
                    </xsl:when>
                    <xsl:when test="$method='RegistrarPagoIFX'">
                        <!-- Incluir en el atributo value el valor correspondiente para esta operacion -->
                        <dp:set-http-request-header name="'Content-type'" value="concat('application/soap+xml;charset=UTF-8;action=&quot;http://tempuri.org/IWCFPagoVentanilla/RegistrarPagoIFXGen&quot;')"/>
                        <dp:freeze-headers/>
                        <!--Variables para la construccion del mensaje Request-->
                        <xsl:variable name="sPNamePago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='SPName']"/>
                        <xsl:variable name="rqUIDPago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='RqUID']"/>
                        <xsl:variable name="bankIdPago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='MsgRqHdr']/*[local-name()='NetworkTrnInfo']/*[local-name()='BankId']"/>
                        <xsl:variable name="curCodePago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='CurAmt']/*[local-name()='CurCode']"/>
                        <xsl:variable name="billIdPago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='RemitInfo']/*[local-name()='BillId']"/>
                        <xsl:variable name="amtPago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='CurAmt']/*[local-name()='Amt']"/>
                        <xsl:variable name="networkOwnerPago" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='MsgRqHdr']/*[local-name()='NetworkTrnInfo']/*[local-name()='NetworkOwner']"/>
                        <xsl:variable name="remitInfoCurAmt" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='RemitInfo']/*[local-name()='CurAmt']/*[local-name()='Amt']"/>
                        <xsl:variable name="custPayeeId" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='RemitInfo']/*[local-name()='CustPayeeId']"/>
                        <xsl:variable name="pmtId" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='RemitInfo']/*[local-name()='PmtId']"/>
                        <xsl:variable name="prcDt" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='PrcDt']"/>
                        <xsl:variable name="clientDt" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientDt']"/>
                        <xsl:variable name="custLangPref" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='CustLangPref']"/>
                        <xsl:variable name="org" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Org']"/>
                        <xsl:variable name="name" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Name']"/>
                        <xsl:variable name="version" select="$srtIFX/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientApp']/*[local-name()='Version']"/>
                        <xsl:variable name="agentId" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='MsgRqHdr']/*[local-name()='PointOfServiceData']/*[local-name()='POSAgent']/*[local-name()='AgentId']"/>
                        <xsl:variable name="pOSLocation" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='MsgRqHdr']/*[local-name()='PointOfServiceData']/*[local-name()='POSLocation']"/>
                        <xsl:variable name="pmtAddRqRqUID" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='RqUID']"/>
                        <xsl:variable name="acctType" select="$srtIFX/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='DepAcctIdFrom']/*[local-name()='AcctType']"/>
                        <!-- Mapeo del Body para notificación del pago: Aqui inicia la mediacion del mensaje request -->
                        <soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">
                            <wsa:Action>http://tempuri.org/IWCFPagoVentanilla/RegistrarPagoIFXGen</wsa:Action>
                            <wsa:To>https://172.25.59.4:59511/WCFPagoVentanillaProxySign/WCFPagoVentanilla.svc</wsa:To>
                        </soap:Header>
                        <soap:Body>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRq>
                                        <ClientDt>
                                            <xsl:value-of select="$clientDt"/>
                                        </ClientDt>
                                        <CustLangPref>
                                            <xsl:value-of select="$custLangPref"/>
                                        </CustLangPref>
                                        <ClientApp>
                                            <Org>
                                                <xsl:value-of select="$org"/>
                                            </Org>
                                            <Name>
                                                <xsl:value-of select="$name"/>
                                            </Name>
                                            <Version>
                                                <xsl:value-of select="$version"/>
                                            </Version>
                                        </ClientApp>
                                    </SignonRq>
                                    <PaySvcRq>
                                        <RqUID>
                                            <xsl:value-of select="$rqUIDPago"/>
                                        </RqUID>
                                        <MsgRqHdr>
                                            <NetworkTrnInfo>
                                                <NetworkOwner>2</NetworkOwner>
                                                <BankId>7</BankId>
                                            </NetworkTrnInfo>
                                            <PointOfServiceData>
                                                <Environment/>
                                                <POSAgent>
                                                    <AgentId>
                                                        <xsl:value-of select="$agentId"/>
                                                    </AgentId>
                                                </POSAgent>
                                                <POSLocation>
                                                    <xsl:value-of select="$pOSLocation"/>
                                                </POSLocation>
                                            </PointOfServiceData>
                                        </MsgRqHdr>
                                        <SPName>100</SPName>
                                        <PmtAddRq>
                                            <RqUID>
                                                <xsl:value-of select="$pmtAddRqRqUID"/>
                                            </RqUID>
                                            <PmtInfo>
                                                <CurAmt>
                                                    <Amt>
                                                        <xsl:value-of select="substring-before($remitInfoCurAmt, '.')"/>
                                                    </Amt>
                                                    <CurCode>
                                                        <xsl:value-of select="$curCodePago"/>
                                                    </CurCode>
                                                </CurAmt>
                                                <RemitInfo>
                                                    <CustPayeeId/>
                                                    <BillId>
                                                        <xsl:value-of select="$billIdPago"/>
                                                    </BillId>
                                                    <BillRefInfo/>
                                                    <PmtId>
                                                        <xsl:value-of select="$pmtId"/>
                                                    </PmtId>
                                                    <CurAmt>
                                                        <Amt>
                                                            <xsl:value-of select="substring-before($remitInfoCurAmt, '.')"/>
                                                        </Amt>
                                                    </CurAmt>
                                                </RemitInfo>
                                                <DepAcctIdFrom>
                                                    <AcctId/>
                                                    <AcctType>
                                                        <xsl:value-of select="$acctType"/>
                                                    </AcctType>
                                                    <BankInfo/>
                                                </DepAcctIdFrom>
                                                <PrcDt>
                                                    <xsl:value-of select="$prcDt"/>
                                                </PrcDt>
                                            </PmtInfo>
                                        </PmtAddRq>
                                    </PaySvcRq>
                                </IFX>
                            </xsl:variable>
                            <tem:RegistrarPagoIFXGen>
                                <!--Optional:-->
                                <tem:infoPago>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/>
                                </tem:infoPago>
                                <!--Optional:-->
                                <tem:codigoBanco>7</tem:codigoBanco>
                            </tem:RegistrarPagoIFXGen>
                        </soap:Body>
                    </xsl:when>
                </xsl:choose>
            </soap:Envelope>
        </xsl:variable>
        <!-- Log/Request | RIN Standard > Servicio Cliente  -->
        <xsl:call-template name="registerLog">
            <xsl:with-param name="logType" select="$LOG_TYPE_REQUEST_OUT"/>
            <xsl:with-param name="processorName" select="$processorName"/>
            <xsl:with-param name="transaccionId" select="$transaccionId"/>
            <xsl:with-param name="convenio" select="$convenio"/>
            <xsl:with-param name="transactionMethod" select="$method"/>
            <xsl:with-param name="message" select="$soapMessage"/>
        </xsl:call-template>
        <xsl:copy-of select="$soapMessage"/>
    </xsl:template>
</xsl:stylesheet>