<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:date="http://exslt.org/dates-and-times"
                xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                xmlns:dp="http://www.datapower.com/extensions"
                xmlns:vcsoft="http://vc-soft.com/vcsoft/functions"
                extension-element-prefixes="date dp"
                exclude-result-prefixes="date dp wsse vcsoft">
    <!-- Se incluyen los XSL requeridos -->
    <xsl:include href="local:///CashManagement/xsl/utils_rin.xsl"/>
    <xsl:include href="local:///common/utils/vcsoft.bancolombia.utilities.xsl"/>
    <xsl:include href="local:///CashManagement/xsl/messaging_handling.xsl"/>
    <xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" version="1.0" method="xml"/>
    <xsl:template match="/">
        <!-- Se consulta el tipo de Log-->
        <xsl:variable name="processorName" select="dp:variable('var://service/processor-name')"/>
        <!-- Extraccion del Mensaje Body-->
        <xsl:variable name="soapBody" select="*[local-name()='Envelope']/*[local-name()='Body']/*[1]"/>
        <!-- Id de la transaccion en DataPower-->
        <xsl:variable name="transaccionId" select="dp:variable('var://service/transaction-id')"/>
        <!-- Id del Convenio-->
        <xsl:variable name="convenio" select="dp:variable('var://context/transaction/convenio')"/>
        <!-- Captura de una posible excepcion -->
        <xsl:variable name="httpError" select="$soapBody/*[local-name()='faultstring']/text()"/>
        <xsl:variable name="SoapAction" select="concat('http://tempuri.org/',$Metodo,'Response')" />
        <!-- IFX Request -->
        <xsl:variable name="srtIFXRq" select="dp:variable('var://context/store/srtIFX')"/>
        <!-- Fecha actual -->
        <xsl:variable name="currentDate">
            <xsl:call-template name="dateFormat">
                <xsl:with-param name="dateTime" select="date:date-time()" />
                <xsl:with-param name="pattern" select="'YYYY-MM-DD'" />
            </xsl:call-template>
        </xsl:variable>
        <!-- Fecha y Hora actual -->
        <xsl:variable name="currentDateTime">
            <xsl:call-template name="dateFormat">
                <xsl:with-param name="dateTime" select="date:date-time()" />
                <xsl:with-param name="pattern" select="'YYYY-MM-DDTHH:mm:ss'" />
            </xsl:call-template>
        </xsl:variable>
        <!-- Log/Response | Cliente -->
        <xsl:call-template name="registerLog">
            <xsl:with-param name="logType" select="$LOG_TYPE_RESPONSE_IN"/>
            <xsl:with-param name="processorName" select="$processorName"/>
            <xsl:with-param name="transaccionId" select="$transaccionId"/>
            <xsl:with-param name="convenio" select="$convenio"/>
            <xsl:with-param name="transactionMethod" select="local-name($soapBody)"/>
            <xsl:with-param name="message" select="$soapBody"/>
        </xsl:call-template>
        <xsl:variable name="soapMessage">
            <soapenv:Envelope>
                <soapenv:Header/>
                <soapenv:Body>
                    <xsl:choose>
                        <!-- Si el metodo es envioTramaDummy se construye mensaje de respuesta -->
                        <xsl:when test="dp:variable('var://context/transaction/method')='envioTramaDummy'">
                            <!--Esta valor debe ser extraido del mensaje del cliente para su homologacion hacia el mensaje IFX de respuesta-->
                            <xsl:copy-of select="vcsoft:buildDummySoapResponse($httpError)/*[local-name()='Envelope']/*[local-name()='Body']/*[1]"/>
                        </xsl:when>
                        <!-- Si el metodo es ConsultarFacturasPorNumero se construye mensaje de respuesta -->
                        <xsl:when test="dp:variable('var://context/transaction/method')='ConsultarFacturaPorNumero'">
                            <!--Esta valor debe ser extraido del mensaje del cliente para su homologacion hacia el mensaje IFX de respuesta-->
                            <xsl:variable name="amtConsulta" select="normalize-space(substring-before(substring-after($soapBody, '&lt;Amt&gt;'), '&lt;/Amt'))"/>                                   
                            <xsl:variable name="statusCode" select="normalize-space(substring-before(substring-after($soapBody, 'StatusCode&gt;'), '&lt;/StatusCode'))"/>
                            <xsl:variable name="clientDtConsulta" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientDt']"/>                               
                            <xsl:variable name="rqUIDConsulta" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='RqUID']"/>
                            <xsl:variable name="billIdConsulta" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='BillId']"/>
                            <xsl:variable name="billingAcct" select="normalize-space(substring-before(substring-after($soapBody, 'BillingAcct&gt;'), '&lt;/BillingAcct'))"/>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRs>
                                        <ClientDt>
                                            <xsl:value-of select="$currentDateTime"/>
                                        </ClientDt>
                                        <CustLangPref>es-CO</CustLangPref>
                                        <ClientApp>
                                            <Org>EPM</Org>
                                            <Name>EPM</Name>
                                            <Version>1</Version>
                                        </ClientApp>
                                        <ServerDt>
                                            <xsl:value-of select="$currentDateTime"/>
                                        </ServerDt>
                                        <Language>es-CO</Language>
                                    </SignonRs>
                                    <PresSvcRs>
                                        <RqUID>
                                            <xsl:value-of select="$rqUIDConsulta"/>
                                        </RqUID>
                                        <BillInqRs>
                                            <!--Este Nodo debe ser homologado tomando como referencia los codigos de respuesta del cliente-->
                                            <Status>
                                                <xsl:choose>
                                                    <xsl:when test="$statusCode='0'">
                                                        <StatusCode>
                                                            <xsl:value-of select="'0'"/>
                                                        </StatusCode>
                                                        <Severity>Info</Severity>
                                                        <StatusDesc>Exitoso</StatusDesc>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:choose>
                                                            <xsl:when test="$statusCode='3548'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10523'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10602'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10603'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10622'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10633'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12024'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12202'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-006'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Nro. De transaccion duplicado</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='12427'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12428'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>   
                                                            <xsl:when test="$statusCode='12431'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12432'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-006'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Nro. De transaccion duplicado</StatusDesc>
                                                            </xsl:when>                                                                                                                                                                               
                                                            <xsl:when test="$statusCode='12438'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12439'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12447'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12448'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12449'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='12452'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12462'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10429'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='6161'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12518'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10726'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='-099'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>                                                                                                                      
                                                        </xsl:choose>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </Status>
                                            <RqUID>
                                                <xsl:value-of select="$rqUIDConsulta"/>
                                            </RqUID>
                                            <!-- Si el codigo de respuesta es exitoso-->
                                            <xsl:if test="$statusCode='0'">
                                                <BillRec>
                                                    <BillId>
                                                        <xsl:value-of select="$billIdConsulta"/>
                                                    </BillId>
                                                    <BillInfo>
                                                        <BillType>Bill</BillType>
                                                        <PresAcctId>
                                                            <BillingAcct>
                                                                <xsl:value-of select="$billingAcct"/>
                                                            </BillingAcct>
                                                            <BillerId>
                                                                <SPName>RIN</SPName>
                                                                <BillerNum>0</BillerNum>
                                                            </BillerId>
                                                        </PresAcctId>
                                                        <BillSummAmt>
                                                            <BillSummAmtCode>Interest</BillSummAmtCode>
                                                            <ShortDesc>Intereses</ShortDesc>
                                                            <CurAmt>
                                                                <Amt>0.00</Amt>
                                                            </CurAmt>
                                                            <BillSummAmtType>Payable</BillSummAmtType>
                                                        </BillSummAmt>
                                                        <BillSummAmt>
                                                            <BillSummAmtCode>Charges</BillSummAmtCode>
                                                            <ShortDesc>Valor Factura Sin intereses</ShortDesc>
                                                            <CurAmt>
                                                                <Amt>
                                                                    <xsl:value-of select="concat($amtConsulta,'.00')"/> 
                                                                </Amt>
                                                            </CurAmt>
                                                            <BillSummAmtType>Payable</BillSummAmtType>
                                                        </BillSummAmt>
                                                        <BillSummAmt>
                                                            <BillSummAmtCode>TotalAmtDue</BillSummAmtCode>
                                                            <ShortDesc>Valor total de la factura</ShortDesc>
                                                            <CurAmt>
                                                                <Amt>
                                                                    <xsl:value-of select="concat($amtConsulta,'.00')"/> 
                                                                </Amt>
                                                            </CurAmt>
                                                            <BillSummAmtType>Payable</BillSummAmtType>
                                                        </BillSummAmt>
                                                        <BillDt>
                                                            <xsl:value-of select="$currentDate"/>
                                                        </BillDt>
                                                    </BillInfo>
                                                </BillRec>
                                            </xsl:if>
                                        </BillInqRs>
                                    </PresSvcRs>
                                </IFX>
                            </xsl:variable>
                            <tem:ConsultarFacturaPorNumeroResponse xmlns:tem="http://tempuri.org/">
                                <tem:ConsultarFacturaPorNumeroResult>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/>
                                </tem:ConsultarFacturaPorNumeroResult>
                            </tem:ConsultarFacturaPorNumeroResponse>
                        </xsl:when>
                        <!-- Si el metodo es ConsultarFacturasPorNegocio se construye mensaje de respuesta -->
                        <xsl:when test="dp:variable('var://context/transaction/method')='ConsultarFacturasPorNegocio'">
                            <!--Esta valor debe ser extraido del mensaje del cliente para su homologacion hacia el mensaje IFX de respuesta-->
                            <xsl:variable name="clientDtNegocio" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='SignonRq']/*[local-name()='ClientDt']"/>
                            <xsl:variable name="rqUIDNegocio" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='RqUID']"/>
                            <xsl:variable name="billerNumNegocio" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PresSvcRq']/*[local-name()='BillInqRq']/*[local-name()='BillerId']/*[local-name()='BillerNum']"/>
                            <xsl:variable name="billingAcct" select="*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='simularReturn']/*[local-name()='R_WSConBcolCC']/*[local-name()='R_Cedula']/*[local-name()='R_BillInqRs']/*[local-name()='R_BillingAcct']"/>
                            <xsl:variable name="statusCode" select="normalize-space(substring-before(substring-after($soapBody, 'StatusCode&gt;'), '&lt;/StatusCode'))"/>
                            <xsl:variable name="amtNegocio" select="normalize-space(substring-before(substring-after($soapBody, '&lt;Amt&gt;'), '&lt;/Amt'))"/>
                            <xsl:variable name="billIdNegocio" select="normalize-space(substring-before(substring-after($soapBody, '&lt;BillId&gt;'), '&lt;/BillId'))"/>
                            <xsl:variable name="cDataToString">
                                <xsl:call-template name="cDataToString">
                                    <xsl:with-param name="cData" select="$soapBody/*[local-name()='ConsultarCuponesGenResult']"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <!--Variable que almacena el cdata del cliente en formato XML-->
                            <xsl:variable name="ifxRs" select="dp:parse($cDataToString)"/>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRs>
                                        <ClientDt>
                                            <xsl:value-of select="$clientDtNegocio"/>
                                        </ClientDt>
                                        <CustLangPref>es-CO</CustLangPref>
                                        <ClientApp>
                                            <Org>EPM</Org>
                                            <Name>EPM</Name>
                                            <Version>1.0</Version>
                                        </ClientApp>
                                        <ServerDt>
                                            <xsl:value-of select="$currentDateTime"/>
                                        </ServerDt>
                                        <Language>es-CO</Language>
                                    </SignonRs>
                                    <PresSvcRs>
                                        <RqUID>
                                            <xsl:value-of select="$rqUIDNegocio"/>
                                        </RqUID>
                                        <BillInqRs>
                                            <!--Este Nodo debe ser homologado tomando como referencia los codigos de respuesta del cliente-->
                                            <Status>
                                                <xsl:choose>
                                                    <xsl:when test="$statusCode='0'">
                                                        <StatusCode>
                                                            <xsl:value-of select="'0'"/>
                                                        </StatusCode>
                                                        <Severity>Info</Severity>
                                                        <StatusDesc>Exitoso</StatusDesc>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:choose>
                                                            <xsl:when test="$statusCode='3548'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10523'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10602'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10603'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10622'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10633'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12024'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12202'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-006'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Nro. De transaccion duplicado</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='12427'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12428'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>   
                                                            <xsl:when test="$statusCode='12431'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12432'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-006'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Nro. De transaccion duplicado</StatusDesc>
                                                            </xsl:when>                                                                                                                                                                               
                                                            <xsl:when test="$statusCode='12438'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12439'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12447'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12448'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12449'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='12452'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12462'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10429'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='6161'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12518'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10726'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='-099'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>                                                                                                                      
                                                        </xsl:choose>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </Status>
                                            <RqUID>
                                                <xsl:value-of select="$rqUIDNegocio"/>
                                            </RqUID>
                                            <!-- Si el codigo de respuesta es exitoso-->
                                            <xsl:if test="$statusCode='0'">
                                                <xsl:choose>
                                                    <xsl:when test="$ifxRs/*[local-name()='ArrayOfIFX']/*[local-name()='IFX']!=''">
                                                        <xsl:for-each select="$ifxRs/*[local-name()='ArrayOfIFX']/*[local-name()='IFX']">
                                                            <BillRec>
                                                                <BillId>
                                                                    <xsl:call-template name="str-uuid">
                                                                        <xsl:with-param name="wCadenaBillId" select="PaySvcRs/PmtAddRs/PmtInfo/RemitInfo/BillId" />
                                                                    </xsl:call-template>
                                                                </BillId>
                                                                <BillInfo>
                                                                    <BillType>Bill</BillType>
                                                                    <PresAcctId>
                                                                        <BillingAcct>
                                                                            <xsl:value-of select="$billingAcct"/>
                                                                        </BillingAcct>
                                                                        <BillerId>
                                                                            <SPName>RIN</SPName>
                                                                            <BillerNum>0</BillerNum>
                                                                        </BillerId>
                                                                    </PresAcctId>
                                                                    <BillSummAmt>
                                                                        <BillSummAmtCode>Interest</BillSummAmtCode>
                                                                        <ShortDesc>Intereses</ShortDesc>
                                                                        <CurAmt>
                                                                            <Amt>0.00</Amt>
                                                                        </CurAmt>
                                                                        <BillSummAmtType>Payable</BillSummAmtType>
                                                                    </BillSummAmt>
                                                                    <BillSummAmt>
                                                                        <BillSummAmtCode>Charges</BillSummAmtCode>
                                                                        <ShortDesc>Valor Factura Sin intereses</ShortDesc>
                                                                        <CurAmt>
                                                                            <Amt>
                                                                                <xsl:value-of select="concat(PaySvcRs/PmtAddRs/PmtInfo/RemitInfo/CurAmt/Amt,'.00')"/> 
                                                                            </Amt>
                                                                        </CurAmt>
                                                                        <BillSummAmtType>Payable</BillSummAmtType>
                                                                    </BillSummAmt>
                                                                    <BillSummAmt>
                                                                        <BillSummAmtCode>TotalAmtDue</BillSummAmtCode>
                                                                        <ShortDesc>Valor total de la factura</ShortDesc>
                                                                        <CurAmt>
                                                                            <Amt>
                                                                                <xsl:value-of select="concat(PaySvcRs/PmtAddRs/PmtInfo/RemitInfo/CurAmt/Amt,'.00')"/> 
                                                                            </Amt>
                                                                        </CurAmt>
                                                                        <BillSummAmtType>Payable</BillSummAmtType>
                                                                    </BillSummAmt>
                                                                    <BillDt>
                                                                        <xsl:value-of select="$currentDate"/>
                                                                    </BillDt>
                                                                </BillInfo>
                                                            </BillRec>
                                                        </xsl:for-each>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:choose>
                                                            <xsl:when test="$ifxRs/*[local-name()='IFX']!=''">
                                                                <BillRec>
                                                                    <BillId>
                                                                        <xsl:call-template name="str-uuid">
                                                                            <xsl:with-param name="wCadenaBillId" select="$billIdNegocio" />
                                                                        </xsl:call-template>
                                                                    </BillId>
                                                                    <BillInfo>
                                                                        <BillType>Bill</BillType>
                                                                        <PresAcctId>
                                                                            <BillingAcct>
                                                                                <xsl:value-of select="$billingAcct"/>
                                                                            </BillingAcct>
                                                                            <BillerId>
                                                                                <SPName>RIN</SPName>
                                                                                <BillerNum>0</BillerNum>
                                                                            </BillerId>
                                                                        </PresAcctId>
                                                                        <BillSummAmt>
                                                                            <BillSummAmtCode>Interest</BillSummAmtCode>
                                                                            <ShortDesc>Intereses</ShortDesc>
                                                                            <CurAmt>
                                                                                <Amt>0.00</Amt>
                                                                            </CurAmt>
                                                                            <BillSummAmtType>Payable</BillSummAmtType>
                                                                        </BillSummAmt>
                                                                        <BillSummAmt>
                                                                            <BillSummAmtCode>Charges</BillSummAmtCode>
                                                                            <ShortDesc>Valor Factura Sin intereses</ShortDesc>
                                                                            <CurAmt>
                                                                                <Amt>
                                                                                    <xsl:value-of select="concat($amtNegocio,'.00')"/> 
                                                                                </Amt>
                                                                            </CurAmt>
                                                                            <BillSummAmtType>Payable</BillSummAmtType>
                                                                        </BillSummAmt>
                                                                        <BillSummAmt>
                                                                            <BillSummAmtCode>TotalAmtDue</BillSummAmtCode>
                                                                            <ShortDesc>Valor total de la factura</ShortDesc>
                                                                            <CurAmt>
                                                                                <Amt>
                                                                                    <xsl:value-of select="concat($amtNegocio,'.00')"/> 
                                                                                </Amt>
                                                                            </CurAmt>
                                                                            <BillSummAmtType>Payable</BillSummAmtType>
                                                                        </BillSummAmt>
                                                                        <BillDt>
                                                                            <xsl:value-of select="$currentDate"/>
                                                                        </BillDt>
                                                                    </BillInfo>
                                                                </BillRec>
                                                            </xsl:when>                                                                                                                      
                                                        </xsl:choose>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:if>
                                        </BillInqRs>
                                    </PresSvcRs>
                                </IFX>
                            </xsl:variable>
                            <tem:ConsultarFacturasPorNegocioResponse xmlns:tem="http://tempuri.org/">
                                <tem:ConsultarFacturasPorNegocioResult>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/>
                                </tem:ConsultarFacturasPorNegocioResult>
                            </tem:ConsultarFacturasPorNegocioResponse>
                        </xsl:when>
                        <!-- Si el metodo es RegistrarPagoIFX se construye mensaje de respuesta -->
                        <xsl:when test="dp:variable('var://context/transaction/method')='RegistrarPagoIFX'">
                            <!--Esta valor debe ser extraido del mensaje del cliente para su homologacion hacia el mensaje IFX de respuesta-->
                            <xsl:variable name="isValidConfirmation" select="string($parsedMessage/*[local-name()='Body']/*[local-name()='BankPaymentConfirmation']/*[local-name()='isValidConfirmation'])"/>
                            <xsl:variable name="rqUIDPago" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='RqUID']"/>
                            <xsl:variable name="sPNamePago" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='SPName']"/>
                            <xsl:variable name="statusCode" select="normalize-space(substring-before(substring-after($soapBody, 'StatusCode&gt;'), '&lt;/StatusCode'))"/>
                            <xsl:variable name="billIdPago" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='RemitInfo']/*[local-name()='BillId']"/>
                            <!-- <xsl:variable name="amtPago" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='CurAmt']/*[local-name()='Amt']"/> -->
                            <xsl:variable name="amtPagoRequest" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='CurAmt']/*[local-name()='Amt']"/>
                            <xsl:variable name="amtPagoRequest2" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='PmtInfo']/*[local-name()='RemitInfo']/*[local-name()='CurAmt']/*[local-name()='Amt']"/>
                            <xsl:variable name="asyncRqUID" select="$srtIFXRq/*[local-name()='IFX']/*[local-name()='PaySvcRq']/*[local-name()='PmtAddRq']/*[local-name()='RqUID']"/>
                            <xsl:variable name="serverDtPago" select="normalize-space(substring-before(substring-after($soapBody, 'ServerDt&gt;'), '&lt;/ServerDt'))"/>
                            <xsl:variable name="varIFX">
                                <IFX>
                                    <SignonRs>
                                        <ClientDt>
                                            <xsl:value-of select="$currentDateTime"/>
                                        </ClientDt>
                                        <CustLangPref>es-CO</CustLangPref>
                                        <ClientApp>
                                            <Org>EPM</Org>
                                            <Name>EPM</Name>
                                            <Version>1.0</Version>
                                        </ClientApp>
                                        <ServerDt>
                                            <xsl:value-of select="$currentDateTime" />
                                        </ServerDt>
                                        <Language>es-CO</Language>
                                    </SignonRs>
                                    <PaySvcRs>
                                        <RqUID>
                                            <xsl:value-of select="$rqUIDPago"/>
                                        </RqUID>
                                        <SPName>RIN</SPName>
                                        <PmtAddRs>
                                            <!--Este Nodo debe ser homologado tomando como referencia los codigos de respuesta del cliente-->
                                            <Status>
                                                <xsl:choose>
                                                    <xsl:when test="$statusCode='0'">
                                                        <StatusCode>
                                                            <xsl:value-of select="'0'"/>
                                                        </StatusCode>
                                                        <Severity>Info</Severity>
                                                        <StatusDesc>Exitoso</StatusDesc>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:choose>
                                                            <xsl:when test="$statusCode='3548'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10523'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10602'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10603'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10622'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10633'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12024'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12202'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-006'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Nro. De transaccion duplicado</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='12427'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12428'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>   
                                                            <xsl:when test="$statusCode='12431'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12432'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-006'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Nro. De transaccion duplicado</StatusDesc>
                                                            </xsl:when>                                                                                                                                                                               
                                                            <xsl:when test="$statusCode='12438'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12439'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12447'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12448'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12449'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='12452'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12462'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10429'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>                                                            
                                                            <xsl:when test="$statusCode='6161'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='12518'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-001'"/>
                                                                </StatusCode>
                                                                <Severity>Info</Severity>
                                                                <StatusDesc>Factura no existe</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='10726'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-002'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Factura ya fue pagada</StatusDesc>
                                                            </xsl:when>
                                                            <xsl:when test="$statusCode='-099'">
                                                                <StatusCode>
                                                                    <xsl:value-of select="'-099'"/>
                                                                </StatusCode>
                                                                <Severity>Error</Severity>
                                                                <StatusDesc>Error tecnico</StatusDesc>
                                                            </xsl:when>                                                                                                                      
                                                        </xsl:choose>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </Status>
                                            <RqUID>
                                                <xsl:value-of select="$rqUIDPago"/>
                                            </RqUID>
                                            <AsyncRqUID>
                                                <xsl:value-of select="$asyncRqUID"/>
                                            </AsyncRqUID>
                                            <PmtInfo>
                                                <RemitInfo>
                                                    <CustPayeeId>0</CustPayeeId>
                                                    <BillId>
                                                        <xsl:value-of select="$billIdPago"/>
                                                    </BillId>
                                                    <CurAmt>
                                                        <Amt>
                                                            <xsl:value-of select="$amtPagoRequest"/>
                                                        </Amt>
                                                    </CurAmt>
                                                </RemitInfo>
                                                <DepAcctIdFrom>
                                                    <AcctId/>
                                                    <AcctType>Default</AcctType>
                                                    <BankInfo/>
                                                </DepAcctIdFrom>
                                                <PrcDt>
                                                    <xsl:value-of select="$currentDate"/>
                                                </PrcDt>
                                            </PmtInfo>
                                            <PmtRec>
                                                <PmtId>0</PmtId>
                                                <PmtInfo>
                                                    <RemitInfo>
                                                        <CustPayeeId>0</CustPayeeId>
                                                        <BillId>
                                                            <xsl:value-of select="$billIdPago"/>
                                                        </BillId>
                                                        <CurAmt>
                                                            <Amt>
                                                                <xsl:value-of select="$amtPagoRequest2"/>
                                                            </Amt>
                                                        </CurAmt>
                                                    </RemitInfo>
                                                    <DepAcctIdFrom>
                                                        <AcctId/>
                                                        <AcctType>Default</AcctType>
                                                        <BankInfo/>
                                                    </DepAcctIdFrom>
                                                    <DueDt>
                                                        <xsl:value-of select="$currentDate"/>
                                                    </DueDt>
                                                </PmtInfo>
                                                <PmtStatus>
                                                    <PmtStatusCode>
                                                        <xsl:choose>
                                                            <!--Este Nodo debe ser homologado tomando como referencia los codigos de respuesta del cliente-->
                                                            <xsl:when test="$statusCode='0'">
                                                                <xsl:value-of select="$processed" />
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="$failed" />
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </PmtStatusCode>
                                                    <EffDt>
                                                        <xsl:value-of select="$currentDateTime"/>
                                                    </EffDt>
                                                </PmtStatus>
                                            </PmtRec>
                                        </PmtAddRs>
                                    </PaySvcRs>
                                </IFX>
                            </xsl:variable>
                            <tem:RegistrarPagoResponse xmlns:tem="http://tempuri.org/">
                                <tem:RegistrarPagoResult>
                                    <dp:serialize select="$varIFX" omit-xml-decl="yes"/>
                                </tem:RegistrarPagoResult>
                            </tem:RegistrarPagoResponse>
                        </xsl:when>
                    </xsl:choose>
                </soapenv:Body>
            </soapenv:Envelope>
        </xsl:variable>
        <!--Inyeccion Cabecera Content-Type -->
        <dp:set-http-response-header name="'Content-type'" value="'text/xml;charset=UTF-8'"/>
        <dp:freeze-headers/>
        <!-- Log/Response | RIN Standard > Servicio Cliente  -->
        <xsl:call-template name="registerLog">
            <xsl:with-param name="logType" select="$LOG_TYPE_RESPONSE_OUT"/>
            <xsl:with-param name="processorName" select="$processorName"/>
            <xsl:with-param name="transaccionId" select="$transaccionId"/>
            <xsl:with-param name="convenio" select="$convenio"/>
            <xsl:with-param name="transactionMethod" select="local-name($soapBody)"/>
            <xsl:with-param name="message" select="$soapMessage"/>
        </xsl:call-template>
        <xsl:copy-of select="$soapMessage"/>
    </xsl:template>
</xsl:stylesheet>